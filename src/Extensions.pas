unit Extensions;


{$reference System.Drawing.dll}


uses
  System,
  System.Drawing;


class function Point.operator+(left, right: Point) := new Point(left.X + right.X, left.Y + right.Y);

class function String.Clip() := self.Substring(self.IndexOf('\') + 1);

class function String.Parent() := self.Substring(0, Math.Max(0, self.LastIndexOf('\')));

end.