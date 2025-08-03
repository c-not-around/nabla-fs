using System.Runtime.Intrinsics.X86;
using System.Windows.Forms;


namespace NablaFs
{
    internal static class Utils
    {
        public static void Info(string text) => MessageBox.Show(text, "Info", MessageBoxButtons.OK, MessageBoxIcon.Information);
        public static void Warning(string text) => MessageBox.Show(text, "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        public static void Error(string text) => MessageBox.Show(text, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
    }

    internal static class FsCompare
    {
        public static unsafe bool CompareLong(byte* p1, byte* p2, int length)
        {
            int   rem  = length & (8 - 1);
            byte* end  = p1 + length;
            byte* tail = end - rem;

            while (p1 <  tail)
            {
                if (*(long*)p1 != *(long*)p2)
                {
                    return false;
                }

                p1 += 8;
                p2 += 8;
            }

            while (p1 < end)
            {
                if (*p1 != *p2)
                {
                    return false;
                }

                p1++;
                p2++;
            }

            return true;
        }

        public static unsafe bool CompareLongUnroll(byte* p1, byte* p2, int length)
        {
            int   rem  = length & (32 - 1);
            byte* tail = p1 + length - rem;

            while (p1 < tail)
            {
                if (*((long*)(p1 + 0)) != *((long*)(p2 + 0)))
                {
                    return false;
                }
                if (*((long*)(p1 + 8)) != *((long*)(p2 + 8)))
                {
                    return false;
                }
                if (*((long*)(p1 + 16)) != *((long*)(p2 + 16)))
                {
                    return false;
                }
                if (*((long*)(p1 + 24)) != *((long*)(p2 + 24)))
                {
                    return false;
                }

                p1 += 32;
                p2 += 32;
            }

            if (rem > 0)
            {
                return CompareLong(p1, p2, rem);
            }

            return true;
        }

        public static unsafe bool CompareSse(byte* p1, byte* p2, int length)
        {
            int   rem  = length & (64 - 1);
            byte* tail = p1 + length - rem;

            const int mask = 0xFFFF;

            while (p1 < tail)
            {
                if (Sse2.MoveMask(Sse2.CompareEqual(Sse2.LoadVector128(p1 + 0), Sse2.LoadVector128(p2 + 0))) != mask)
                {
                    return false;
                }
                if (Sse2.MoveMask(Sse2.CompareEqual(Sse2.LoadVector128(p1 + 16), Sse2.LoadVector128(p2 + 16))) != mask)
                {
                    return false;
                }
                if (Sse2.MoveMask(Sse2.CompareEqual(Sse2.LoadVector128(p1 + 32), Sse2.LoadVector128(p2 + 32))) != mask)
                {
                    return false;
                }
                if (Sse2.MoveMask(Sse2.CompareEqual(Sse2.LoadVector128(p1 + 48), Sse2.LoadVector128(p2 + 48))) != mask)
                {
                    return false;
                }

                p1 += 64;
                p2 += 64;
            }

            if (rem > 0)
            {
                return CompareLongUnroll(p1, p2, rem);
            }

            return true;
        }

        public static unsafe bool CompareAvx(byte* p1, byte* p2, int length)
        {
            int   rem  = length & (128 - 1);
            byte* tail = p1 + length - rem;
            
            const int mask = -1;

            while (p1 < tail)
            {
                if (Avx2.MoveMask(Avx2.CompareEqual(Avx.LoadVector256(p1 + 0), Avx.LoadVector256(p2 + 0))) != mask)
                {
                    return false;
                }
                if (Avx2.MoveMask(Avx2.CompareEqual(Avx.LoadVector256(p1 + 32), Avx.LoadVector256(p2 + 32))) != mask)
                {
                    return false;
                }
                if (Avx2.MoveMask(Avx2.CompareEqual(Avx.LoadVector256(p1 + 64), Avx.LoadVector256(p2 + 64))) != mask)
                {
                    return false;
                }
                if (Avx2.MoveMask(Avx2.CompareEqual(Avx.LoadVector256(p1 + 96), Avx.LoadVector256(p2 + 96))) != mask)
                {
                    return false;
                }

                p1 += 128;
                p2 += 128;
            }

            if (rem > 0)
            {
                return CompareLongUnroll(p1, p2, rem);
            }

            return true;
        }

        public static unsafe bool Compare(byte[] chunk1, byte[] chunk2, int length)
        {
            fixed (byte* p1 = chunk1, p2 = chunk2)
            {
                if (length >= 1024)
                {
                    if (Avx2.IsSupported)
                    {
                        return CompareAvx(p1, p2, length);
                    }

                    if (Sse2.IsSupported)
                    {
                        return CompareSse(p1, p2, length);
                    }
                }
                
                return CompareLongUnroll(p1, p2, length);
            }
        }
    }
}