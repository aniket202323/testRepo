Create Procedure dbo.spPO_GetSheetData
@DisplayName nvarchar(50),
@UserId Int
  AS
Declare @Isactive 	 Int,
 	 @SheetType 	 Int,
 	 @SheetId 	 Int,
 	 @GroupId 	 Int,
 	 @UserSecurity 	 Int,
 	 @LineId 	  	 int
Select @LineId = -1
Select @GroupId = Null
  SELECT @LineId = PL_Id,@IsActive = Is_Active,@SheetType = Sheet_Type,@SheetId = Sheet_Id, @GroupId = Coalesce(s.Group_Id, sg.Group_Id)
    FROM Sheets s
    Left Outer Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id
    where Sheet_Desc = @DisplayName
  If @IsActive <> 1 
    Select @LineId = -2
  If @SheetType <> 8 
    Select @LineId = -3
If @lineId is null
  Begin
    Select PL_Id = @LineId,s.PU_Id,p.PU_Desc,s.Sheet_Id, Group_Id = @GroupId,UnitTypeId = Coalesce(Unit_Type_Id,1)
 	 From Sheet_Unit s
 	 Join Prod_Units p On p.Pu_Id = s.PU_Id
 	 Where s.Sheet_Id = @SheetId
  End
Else
   Select Pl_Id = @LineId,Sheet_Id = @SheetId, Group_Id = @GroupId
Select TopicNumber = value 
    From Sheet_Display_Options
Where Sheet_id = @SheetId and Display_Option_Id = 1
Select SheetView = Value
    From Sheet_Display_Options
Where Sheet_id = @SheetId and Display_Option_Id = 3
If @lineId is null
   Select Positions = Value
 	 From Sheet_Display_Options s 
 	 Where s.Sheet_Id = @SheetId and s.Display_Option_Id = 159
Else
   Select PL_Id,Positions = Convert(VarChar(7000),OverView_Positions)
 	 From Prod_Lines
 	 Where PL_Id <> 0
Select @GroupId = Null
Select @GroupId = Coalesce(s.Group_Id, sg.Group_Id)
 	 From Sheets s
  Left Outer Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id
 	 Where Sheet_Id = @SheetId
If @GroupId is  Null 
    Select SheetAccess = 3
Else 
  Begin
    Select @UserSecurity = Null
    Select @UserSecurity = Access_Level
 	 From User_Security
 	 Where User_Id = @UserId and Group_Id = @GroupId
    If @UserSecurity is null
 	  Select SheetAccess = -1
    Else
 	  Select SheetAccess = @UserSecurity
  End
Select DisplayHyperLinks = Value
    From Sheet_Display_Options
Where Sheet_id = @SheetId and Display_Option_Id = 229
