CREATE PROCEDURE dbo.spServer_CmnGetEventStatusIdByCode
@Event_Status_Code nVarChar(50),
@UseLike int,
@AutoCreate Int,
@PU_Id Int,
@Event_Status_Id Int OUTPUT
 AS
Set Nocount ON
Declare
  @NumStatuses int,
 	 @Code_Search nvarchar(50)
 	 
Select @Event_Status_Id = NULL
If (@Event_Status_Code <> '')
 	 Begin
 	  	 If (@UseLike = 0)
   	  	 Select @Event_Status_Id = ProdStatus_Id From Production_Status Where ProdStatus_Desc = @Event_Status_Code
 	  	 Else
   	  	 Begin
     	  	 Select @Code_Search = @Event_Status_Code + '%'
     	  	 Select @NumStatuses = Count(ProdStatus_Id) From Production_Status Where ProdStatus_Desc Like @Code_Search
     	  	 If (@NumStatuses = 1)
       	  	 Select @Event_Status_Id = ProdStatus_Id From Production_Status Where ProdStatus_Desc Like @Code_Search
     	  	 Else
       	  	 Select @Event_Status_Id = NULL
   	  	 End
 	 End
If (@AutoCreate = 1) and (@Event_Status_Id Is Null)
 	 Begin
 	  	 EXECUTE spEMPSC_ProductionStatusConfigUpdate Null,Null,Null,1,1,1,@Event_Status_Code
 	  	 Select @Event_Status_Id = ProdStatus_Id From Production_Status Where ProdStatus_Desc = @Event_Status_Code
 	 End
If (@AutoCreate = 0) and (@Event_Status_Id Is Null) and (not @PU_Id is null)
 	 Begin
 	  	 Select @Event_Status_Id = Min(Valid_Status) From prdexec_status Where Is_Default_Status = 1 and PU_Id = @PU_Id
 	  	 If @Event_Status_Id is null
 	  	  	 Select @Event_Status_Id = 5
 	 End
If (@Event_Status_Id Is Null)
  Select @Event_Status_Id = 0
