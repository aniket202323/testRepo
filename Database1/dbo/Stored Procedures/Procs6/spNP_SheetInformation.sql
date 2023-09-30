Create Procedure dbo.spNP_SheetInformation
    @SheetDesc nvarchar(50)
  , @GetOptions Int = NULL 
 AS
DECLARE @Sheet_Id Int, @Sheet_Type Int, @PU_Id Int
IF @GetOptions is Null SET @GetOptions = 1
SELECT @Sheet_Type = Sheet_Type, @PU_Id = Master_Unit FROM Sheets WHERE Sheet_Desc = @SheetDesc
SELECT Sheet_Id
     , Sheet_Desc
     , Is_Active
     , Display_Description
     , Group_Id = COALESCE(s.Group_Id, s1.Group_Id)
     , Comment_Id
     , Sheet_Type
     , s.Sheet_Group_Id
     , PL_Id
  FROM sheets s 
  LEFT OUTER JOIN Sheet_Groups s1 ON s1.Sheet_Group_Id = s.Sheet_Group_Id
 WHERE sheet_desc = @SheetDesc AND Sheet_Type = 27 -- NonProductive Time View 
IF @GetOptions = 2
BEGIN
  Select @Sheet_Id = Sheet_Id From Sheets Where Sheet_Desc = @SheetDesc
    DECLARE @Display_Options Table (
      Display_Option_Id int, 
      Display_Option_Desc nVarchar(100),
      Value nVarchar(100)
      )
    Insert into @Display_Options (Display_Option_Id, Display_Option_Desc, Value)
    Select do.Display_Option_Id, do.Display_Option_Desc, sdo.Value
      From Sheet_Display_Options sdo
      Join Display_Options do on do.Display_Option_Id = sdo.Display_Option_Id
      Where sdo.Sheet_Id = @Sheet_id and COALESCE(sdo.Value, '') <> ''
    Insert into @Display_Options (Display_Option_Id, Display_Option_Desc, Value)
    Select stdo.Display_Option_Id, do.Display_Option_Desc, stdo.Display_Option_Default
      From Sheet_Type_Display_Options stdo
      Join Display_Options do on do.Display_Option_Id = stdo.Display_Option_Id
      Where stdo.Display_Option_Id not in (Select Display_Option_Id from @Display_Options)
        and stdo.Sheet_Type_Id = @Sheet_Type
        and stdo.Display_Option_Default is not NULL
    Select Display_Option_Id, Display_Option_Desc, Value 
    from @Display_Options 
    order by Display_Option_Desc
END
