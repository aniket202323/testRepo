CREATE PROCEDURE dbo.spEM_IEImportDisplayUnits
@SheetDesc 	  	 nVarChar(100),
@PlDesc 	  	  	 nVarChar(100),
@PuDesc 	  	  	 nVarChar(100),
@UserId 	  	  	 int
As
Declare @PlId int,
 	 @PuId int,
 	 @SheetId int
/* Initialization */
Select 	 @PlId 	  	 = Null,
 	  	 @PuId 	  	 = Null,
 	  	 @SheetId 	 = Null
Select @SheetDesc 	 = LTrim(RTrim(@SheetDesc))
Select @PlDesc 	  	 = LTrim(RTrim(@PlDesc))
Select @PuDesc 	  	 = LTrim(RTrim(@PuDesc))
IF @PlDesc = '' SELECT @PlDesc = Null
IF @PuDesc = '' SELECT @PuDesc = Null
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
If @PlDesc is null
BEGIN
  Select 'Failed - missing Production Line'
  Return(-100)
END
If @PuDesc is null
BEGIN
  Select 'Failed - missing Production Unit'
  Return(-100)
END
Select @PlId = PL_Id
 	 From Prod_Lines
 	 Where PL_Desc = @PlDesc
If @PlId is null
BEGIN
  Select 'Failed - unable to find Production Line'
  Return(-100)
END
Select @PuId = PU_Id
 	 From Prod_Units
 	 Where PU_Desc = @PuDesc And PL_Id = @PlId
If @PuId is null
BEGIN
  Select 'Failed - Production unit not found'
  Return(-100)
END
If Not Exists(Select * from Sheet_Unit Where Sheet_Id = @SheetId and PU_Id = @PuId)
 	 Insert into  Sheet_Unit (Sheet_Id,PU_Id) Values (@SheetId,@PuId)
Return(0)
