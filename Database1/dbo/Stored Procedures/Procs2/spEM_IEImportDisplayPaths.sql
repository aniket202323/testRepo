CREATE PROCEDURE dbo.spEM_IEImportDisplayPaths
@SheetDesc 	  	 nVarChar(100),
@PathCode 	  	 nVarChar(100),
@UserId 	  	  	 int
As
Declare @PathId int,
 	  	 @SheetId int
/* Initialization */
Select 	 @PathId 	  	 = Null,
 	  	 @SheetId 	 = Null
Select @SheetDesc 	 = LTrim(RTrim(@SheetDesc))
Select @PathCode 	 = LTrim(RTrim(@PathCode))
IF @PathCode = ''  SELECT @PathCode = Null
IF @SheetDesc = '' SELECT @SheetDesc = Null
If  @SheetDesc IS NULL 
BEGIN
  Select 'Failed - missing display description'
  Return(-100)
END
/* Get Sheet_Id */
Select @SheetId = Sheet_Id
From Sheets
Where Sheet_Desc =@SheetDesc
If @SheetId Is Null
    BEGIN
      Select 'Failed - Unable to find display'
      Return(-100)
    END
If @PathCode is null
BEGIN
  Select 'Failed - missing Path Code'
  Return(-100)
END
Select @PathId = Path_Id
 	 From PrdExec_Paths
 	 Where Path_Code = @PathCode
If @PathId is null
BEGIN
  Select 'Failed - unable to find Path Code'
  Return(-100)
END
If Not Exists(Select * from Sheet_Paths Where Sheet_Id = @SheetId and Path_Id = @PathId)
 	 Insert into  Sheet_Paths (Sheet_Id,Path_Id) Values (@SheetId,@PathId)
Return(0)
