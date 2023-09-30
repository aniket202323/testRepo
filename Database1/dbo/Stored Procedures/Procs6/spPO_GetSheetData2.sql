Create Procedure dbo.spPO_GetSheetData2
@DisplayName nvarchar(50),
@UserId Int
  AS
Declare @Isactive 	 Int,
 	 @SheetType 	 Int,
 	 @SheetId 	 Int,
 	 @GroupId 	 Int,
 	 @UserSecurity 	 Int,
 	 @LineId 	  	 int,
    @LineDesc 	 nvarchar(50),
 	 @DbTZ 	  	 nvarchar(100)
select @DbTZ=value from site_parameters where parm_id=192
Select @LineId = -1
Select @GroupId = Null
  SELECT @LineId = s.PL_Id,@IsActive = Is_Active,@SheetType = Sheet_Type,@SheetId = Sheet_Id, @GroupId = coalesce(s.Group_Id, sg.Group_Id), @LineDesc = PL.PL_Desc
    FROM Sheets s
    Left Outer Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id
    Left Outer Join Prod_Lines pl on pl.PL_Id = s.PL_Id
    where Sheet_Desc = @DisplayName
  If @IsActive <> 1 
    Select @LineId = -2
  If @SheetType <> 8 
    Select @LineId = -3
If @lineId is null
  Begin
    Select PL_Id = @LineId,s.PU_Id,p.PU_Desc,s.Sheet_Id, Group_Id = @GroupId,UnitTypeId = 1,UnitTimeZone = isnull(Time_Zone,@DbTZ)
 	 From Sheet_Unit s
 	 Join Prod_Units p On p.Pu_Id = s.PU_Id
 	 Join Prod_Lines pl On pl.PL_Id = p.PL_Id
 	 Join Departments d on d.Dept_Id = pl.Dept_Id
 	 Where s.Sheet_Id = @SheetId
  End
Else
   Select Pl_Id = @LineId,Sheet_Id = @SheetId, Group_Id = @GroupId, PL_Desc = @LineDesc
/*
Select TopicNumber = value 
    From Sheet_Display_Options
Where Sheet_id = @SheetId and Display_Option_Id = 1
Select SheetView = Value
    From Sheet_Display_Options
Where Sheet_id = @SheetId and Display_Option_Id = 3
*/
If @lineId is null
   Select Positions = Value
 	 From Sheet_Display_Options s 
 	 Where s.Sheet_Id = @SheetId and s.Display_Option_Id = 159
Else
   Select PL_Id,Positions = Convert(VarChar(7000),OverView_Positions)
 	 From Prod_Lines
 	 Where PL_Id <> 0
Select @GroupId = Null
Select @GroupId = coalesce(s.Group_Id, sg.Group_Id)
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
/*
Select DisplayHyperLinks = Value
    From Sheet_Display_Options
Where Sheet_id = @SheetId and Display_Option_Id = 229
*/
Create Table #Options(Display_Option_Id Int,value Varchar(7000),Binary_Id Int,DisplayOptionDesc nvarchar(100))
Insert INto #Options (Display_Option_Id ,value,Binary_Id,DisplayOptionDesc)
     Select st.Display_Option_Id,[value] = case when Value is null then Display_Option_Default
 	                                    Else 	  	 Value
 	  	  	            	  	  	  	  	 End ,Binary_Id,Display_Option_Desc
 	 From Sheet_Type_Display_Options st
    Left Join Sheet_Display_Options sdo on  Sheet_id = @SheetId and st.Display_Option_Id = sdo.Display_Option_Id
 	 Join Display_Options do on do.Display_Option_Id = st.Display_Option_Id
    Where st.Sheet_Type_Id = @SheetType
  Insert into #Options (Display_Option_Id, value, Binary_Id, DisplayOptionDesc)
  Select stdo.Display_Option_Id, stdo.Display_Option_Default, NULL, do.Display_Option_Desc
    From Sheet_Type_Display_Options stdo
    Join Display_Options do on do.Display_Option_Id = stdo.Display_Option_Id
    Where stdo.Display_Option_Id not in (Select Display_Option_Id from #Options)
      and stdo.Sheet_Type_Id = @SheetType
      and stdo.Display_Option_Default is not NULL
  Select * from #Options Where value is not Null
--Result Set of all Units for this line
If @LineId is not Null
  Begin
   Select PU_Id
    From Prod_Units
    Where PL_Id = @LineId
  End
Else
  Select PU_Id from Sheet_Unit Where Sheet_Id = @SheetId
