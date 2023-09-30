CREATE PROCEDURE dbo.spEM_IEImportEngineeringUnit
@EngDesc 	 nvarchar(255),
@EngCode 	  	 nvarchar(255),
@User_Id  	  	  	 Int
AS
Declare 	 @EngId 	  	 Int
Select @EngDesc = LTrim(RTrim(@EngDesc))
Select @EngCode = LTrim(RTrim(@EngCode))
If @EngDesc = '' Select @EngDesc = null
If @EngCode = '' Select @EngCode = null
/*Check From Desc*/
If @EngDesc IS NULL
    Begin
      Select 'Failed - From engineering description missing'
      RETURN (-100)
    End
Select @EngId = Eng_Unit_Id 
 	 From Engineering_Unit
  Where Eng_Unit_Desc = @EngDesc
If @EngId IS Not NULL 
 	 Begin
    Select 'Failed - From engineering unit description already exists'
    RETURN (-100)
 	 End
/*Check From Code*/
If @EngCode IS NULL
    Begin
      Select 'Failed - From engineering code missing'
      RETURN (-100)
    End
Select @EngId = Eng_Unit_Id 
 	 From Engineering_Unit
  Where Eng_Unit_Code = @EngCode
If @EngId IS Not NULL 
 	 Begin
    Select 'Failed - From engineering unit code already exists'
    RETURN (-100)
 	 End
Execute spEM_EUCreate @EngDesc,@EngCode,@User_Id,@EngId output
If @EngId IS NULL
 	 Begin
    Select 'Failed - Could not create engineering unit'
    RETURN (-100)
 	 End
RETURN(0)
