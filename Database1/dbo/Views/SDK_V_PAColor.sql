CREATE view SDK_V_PAColor
as
select
Colors.Color_Id as Id,
Colors.Color_Desc as Color,
Colors.Color as ColorRGB
from Colors
