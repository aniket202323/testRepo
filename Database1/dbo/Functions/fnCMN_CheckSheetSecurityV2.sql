/*
 	 TableId
 	  	 1 = Downtime, KeyId is a Unit Id
 	  	 2 = ScheduleView, KeyId is a Path Id
*/
CREATE FUNCTION dbo.fnCMN_CheckSheetSecurityV2(
 	  	  	  	  	 @KeyId 	  	  	 int, 
 	  	  	  	  	 @TableId 	  	 Int,
 	  	  	  	  	 @Option1 	  	 Int, 
 	  	  	  	  	 @Option2 	  	 Int,
 	  	  	  	  	 @DefaultLevel 	 Int,
 	  	  	  	  	 @UsersSecurity 	 Int) 
  	  RETURNS  Int
AS 
BEGIN
 	 DECLARE @CurrentLevel Int
 	 DECLARE @OKay Int
 	 SET @CurrentLevel = Null
 	 IF @Option1 is Not Null  Or @Option2 Is Not Null
 	 BEGIN
 	  	 Select @CurrentLevel = MIN(a.Value)
 	  	  	 from Sheet_Display_options a
 	  	  	 Join display_Options b on b.Display_Option_Id = a.Display_Option_Id
 	  	  	 Join Sheet_Type_Display_Options c on c.Display_Option_Id = b.Display_Option_Id 
 	  	  	 Join Sheets s on s.Sheet_Id = a.Sheet_Id 
 	  	  	 Left Join Sheet_Unit su on su.sheet_Id = s.sheet_Id
 	  	  	 Left Join Sheet_Paths sp on sp.sheet_Id = s.sheet_Id
 	  	  	 WHERE  (@TableId = 1 and a.Display_Option_Id = @Option1 and ((Sheet_Type_Id = 5  and s.Master_Unit = @KeyId) or (Sheet_Type_Id = 15  and su.PU_Id = @KeyId))) 
 	  	  	  	 or (@TableId = 1 and a.Display_Option_Id = @Option2 and Sheet_Type_Id = 28  and su.PU_Id = @KeyId) 
 	  	  	  	 or (@TableId = 2 and a.Display_Option_Id = @Option1 and Sheet_Type_Id = 17  and sp.Path_Id = @KeyId) 
 	 END
 	 SELECT @CurrentLevel = Coalesce(@CurrentLevel,@DefaultLevel) -- Default
 	 IF @UsersSecurity >= @CurrentLevel
 	  	 SET @OKay = 1
 	 ELSE
 	  	 SET @OKay = 0
 	 Return @OKay
END
