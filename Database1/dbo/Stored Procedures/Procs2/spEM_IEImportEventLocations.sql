CREATE PROCEDURE dbo.spEM_IEImportEventLocations
 	 @PL_Desc 	  nvarchar(50),
 	 @PU_Desc 	  nvarchar(50),
 	 @ET_Desc 	  nvarchar(50),
  @Location_Desc  nvarchar(50),
  @Tree_Name nvarchar(50),
  @ActionTreeName nvarchar(50),
  @Research nvarchar(50),
 	 @User_Id 	  int
AS
Declare 	 @PL_Id int,
 	  	     @PU_Id int,
        @ET_Id int,
        @Location_Id int,
        @Tree_Name_Id int,
        @ActionTreeId int,
        @Based tinyint,
        @ResearchEnabled Int
Select @PL_Id = Null
Select @PU_Id = Null
Select @ET_Id = Null
Select @Location_Id = Null
Select @Tree_Name_Id = Null
Select @ActionTreeId = Null
Select @Based = Null
------------------------------------------------------------------------------------------
-- Trim Parameters
------------------------------------------------------------------------------------------
Select @PL_Desc = LTrim(RTrim(@PL_Desc))
Select @PU_Desc = LTrim(RTrim(@PU_Desc))
Select @ET_Desc = LTrim(RTrim(@ET_Desc))
Select @Location_Desc = LTrim(RTrim(@Location_Desc))
Select @Tree_Name = LTrim(RTrim(@Tree_Name))
Select @ActionTreeName = LTrim(RTrim(@ActionTreeName))
SELECT @Research =  LTrim(RTrim(@Research))
IF @PL_Desc = '' SET @PL_Desc = Null
IF @PU_Desc = '' SET @PU_Desc = Null
IF @ET_Desc = '' SET @ET_Desc = Null
IF @Location_Desc = '' SET @Location_Desc = Null
IF @ActionTreeName = '' SET @ActionTreeName = Null
IF @Research = '' SET @Research = '0'
If @Research = '1'
 	 Select @ResearchEnabled = 1
ELSE
 	 Select @ResearchEnabled = 0
-- Verify Arguments 
If @PL_Desc IS NULL
 BEGIN
   Select 'Failed - Production Line Missing'
   Return(-100)
 END
If @PU_Desc IS NULL
 BEGIN
   Select 'Failed - Production Unit Missing'
   Return(-100)
 END
If @ET_Desc IS NULL
 BEGIN
   Select 'Failed - Event Type Missing'
   Return(-100)
 END
If @Location_Desc IS NULL
 BEGIN
   Select 'Failed - Location Missing'
   Return(-100)
 END
If @ActionTreeName Is Null and @Tree_Name IS NULL
 BEGIN
   Select 'Failed - Tree Name Missing'
   Return(-100)
 END
------------------------------------------------------------------------------------------
--Insert or Update Event Locations
------------------------------------------------------------------------------------------
Select @PL_Id = PL_Id 
  from Prod_Lines
  where PL_Desc = @PL_Desc
If @PL_Id IS NULL
 BEGIN
   Select 'Failed - Production Line Not Found'
   Return(-100)
 END
Select @PU_Id = PU_Id 
  from Prod_Units
  where PU_Desc = @PU_Desc
  and PL_Id = @PL_Id
If @PU_Id IS NULL
 BEGIN
   Select 'Failed - Production Unit Not Found'
   Return(-100)
 END
If @ET_Desc = 'Downtime'
  Begin
    Select @ET_Id = 2
    Select @Based = 1
  End
Else
  Begin
    Select @ET_Id = 3
    If (Select Patindex('%Event%', @ET_Desc)) > 0
      Select @Based = 1
    Else
      Select @Based = 2
  End
-- Select @ET_Id = ET_Id 
--   from Event_Types
--   where ET_Desc = @ET_Desc
Select @Location_Id = PU_Id 
  from Prod_Units
  where PU_Desc = @Location_Desc
  and PL_Id = @PL_Id
If @Location_Id IS NULL
 BEGIN
   Select 'Failed - Location Not Found'
   Return(-100)
 END
IF @Tree_Name Is Not Null
BEGIN
 	 Select @Tree_Name_Id = Tree_Name_Id 
 	   from Event_Reason_Tree
 	   where Tree_Name = @Tree_Name
 	  If @Tree_Name_Id IS NULL 
 	   BEGIN
 	  	 Select 'Failed - Cause Tree Name Not Found'
 	  	 Return(-100)
 	   END
END
IF @ActionTreeName Is Not Null
BEGIN
 	 Select @ActionTreeId = Tree_Name_Id 
 	   from Event_Reason_Tree
 	   where Tree_Name = @ActionTreeName
 	  If @ActionTreeId IS NULL 
 	   BEGIN
 	  	 Select 'Failed - Action Tree Name Not Found'
 	  	 Return(-100)
 	   END
END
If (@PU_Id <> @Location_Id) and (Select Count(*) From Prod_Units Where Master_Unit = @PU_Id and PU_Id = @Location_Id) = 0
 BEGIN
   Select 'Failed - Invalid Location For Selected Production Unit'
   Return(-100)
 END
EXECUTE spEMSEC_PutEventConfigInfo @Location_Id,@ET_Id,@Tree_Name_Id,@ActionTreeId,@ResearchEnabled,@Based,@User_Id
----Add Location
--exec spEMEC_DTAssociation @Location_Id, @ET_Id, @Based, @User_Id
----Add Reason
--exec spEMEC_PutProdEvents @Location_Id, @Tree_Name_Id, @ET_Id, @User_Id
Return(0)
