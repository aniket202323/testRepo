CREATE PROCEDURE dbo.spEM_IEImportProductionStatuses
@ProdStatus_Desc  	  	  	 nvarchar(50),
@Icon_Desc  	  	  	  	  	 nvarchar(50),
@Color_Desc  	  	  	  	 nvarchar(50),
@Status_Valid_For_Input_Str 	 nvarchar(50),
@Count_Inv_Str 	  	  	  	 nvarchar(50),
@Count_Production_Str 	  	 nvarchar(50),
@UserId  	  	  	  	  	 int
AS
Declare 	 @Icon_Id 	  	  	 int,
 	 @Color_Id 	  	  	  	 int,
 	 @Status_Valid_For_Input 	 int,
 	 @Count_Inv 	  	  	  	 int,
 	 @Count_Production 	  	 int,
 	 @ProdStatus_Id 	  	  	 Int
/* Initialize */
Select  	 @Icon_Id  	  	  	 = Null,
 	 @Color_Id 	  	  	 = Null,
 	 @Status_Valid_For_Input 	 = 1
/* Clean and verify arguments */
Select 	 @Icon_Desc  	  	  	 = LTrim(RTrim(@Icon_Desc)),
 	 @Color_Desc  	  	  	 = LTrim(RTrim(@Color_Desc)),
 	 @ProdStatus_Desc  	  	 = LTrim(RTrim(@ProdStatus_Desc)),
 	 @Status_Valid_For_Input_Str  	 = LTrim(RTrim(@Status_Valid_For_Input_Str)),
 	 @Count_Inv_Str 	  	   	 = LTrim(RTrim(@Count_Inv_Str)),
 	 @Count_Production_Str  	 = LTrim(RTrim(@Count_Production_Str))
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Configuration Ids 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
Select @Icon_Id = Icon_Id
From Icons
Where Icon_Desc = @Icon_Desc
/*  -- Allow nulls
If @Icon_Id Is Null 
  Begin
     Select 'Failed - icon not found'
     RETURN (-100)
  End
*/
Select @Color_Id = Color_Id
  From Colors
  Where Color_Desc = @Color_Desc
/*  -- Allow nulls
If @Color_Id Is Null 
 Begin
 	 Select 'Failed - color not found'
    RETURN (-100)
 End
*/
If isnumeric(@Status_Valid_For_Input_Str) <> 0
  Begin
 	 If @Status_Valid_For_Input_Str = '1'
     Select @Status_Valid_For_Input = 1
 	 Else 
     Select @Status_Valid_For_Input = 0
  End
Else
  Begin
 	 Select 'Failed - invalid status valid for input'
 	 RETURN (-100)
  End
If isnumeric(@Count_Inv_Str) <> 0
  Begin
 	 If @Count_Inv_Str = '1'
     Select @Count_Inv = 1
 	 Else 
     Select @Count_Inv = 0
  End
Else
  Begin
 	 Select 'Failed - invalid count For inventory'
 	 RETURN (-100)
  End
If isnumeric(@Count_Production_Str) <> 0
  Begin
 	 If @Count_Production_Str = '1'
     Select @Count_Production = 1
 	 Else 
     Select @Count_Production = 0
  End
Else
  Begin
 	 Select 'Failed - invalid count for production'
 	 RETURN (-100)
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Create Production Status 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
Select @ProdStatus_Id = ProdStatus_Id
 	 From Production_Status
 	 Where ProdStatus_Desc = @ProdStatus_Desc
     Begin
 	  	 Execute spEMPSC_ProductionStatusConfigUpdate @ProdStatus_Id, @Icon_Id, @Color_Id,
 	  	  	  @Count_Production,@Count_Inv,@Status_Valid_For_Input, @ProdStatus_Desc
     	 Select @ProdStatus_Id = ProdStatus_Id
 	    	  	 From Production_Status
 	  	  	 Where ProdStatus_Desc = @ProdStatus_Desc
      	 If @ProdStatus_Id Is Null
          Begin
         	 Select 'Failed - unable to create Production Status'
         	 RETURN (-100)
        	   End
     End
RETURN(0)
