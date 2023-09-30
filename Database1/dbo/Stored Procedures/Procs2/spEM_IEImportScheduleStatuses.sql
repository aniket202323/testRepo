CREATE PROCEDURE dbo.spEM_IEImportScheduleStatuses
@PP_Status_Desc nVarChar(100),
@UserId Int 	 
AS
Declare 
  @Description nVarChar(100),
  @PP_Status_Id 	 Int
 	  	 
/* Initialization */
Select @PP_Status_Id = Null
/******************************************************************************************/
/* Create/Update Schedule Statuses 	  	    	  	  	  	                                           */
/******************************************************************************************/
Select @Description = RTrim(LTrim(@PP_Status_Desc))
If @Description = '' or @Description IS NULL
 BEGIN
   Select  'Failed - schedule status field required'
   Return(-100)
 END
If LEN(@Description) > 50
 BEGIN
   Select  'Failed - schedule status too long (Max 50)'
   Return(-100)
 END
Select @PP_Status_Id = PP_Status_Id
From Production_Plan_Statuses
Where PP_Status_Desc = @Description
If @PP_Status_Id Is Null
  Begin
   	 Execute spEM_CreateScheduleStatus @Description, @UserId, @PP_Status_Id Output
   	 If @PP_Status_Id is Null
      Begin
        Select 'Failed - error creating schedule status'
        Return (-100)
      End
  End
