CREATE PROCEDURE dbo.spEM_IEImportAlarmTemplateData
@AT_Desc 	  	  	 nvarchar(50),
@PL_Desc 	  	  	 nvarchar(50),
@PU_Desc 	  	  	 nvarchar(50),
@Var_Desc 	  	  	 nvarchar(50),
@EmailGroup 	  	  	 nvarchar(50),
@User_Id  	  	  	 int
AS
Declare @AT_Id 	  	 int,
 	 @PL_Id 	  	  	 int,
 	 @PU_Id 	  	  	 int,
 	 @Var_Id 	  	  	 int,
 	 @ATD_Id  	  	 int,
 	 @EGId 	  	  	 int
/* Initialization */
Select 	 @AT_Id 	  	 = Null,
 	  	 @ATD_Id 	  	 = Null,
 	  	 @PL_Id 	  	 = Null,
 	  	 @PU_Id 	  	 = Null,
 	  	 @Var_Id 	  	 = Null
/* Clean Arguments */
Select 	 @AT_Desc  	  	 = LTrim(RTrim(@AT_Desc)),
 	 @PL_Desc  	  	 = LTrim(RTrim(@PL_Desc)),
 	 @PU_Desc  	  	 = LTrim(RTrim(@PU_Desc)),
 	 @Var_Desc  	  	 = LTrim(RTrim(@Var_Desc)),
 	 @EmailGroup  	  	 = LTrim(RTrim(@EmailGroup))
IF @EmailGroup = '' SELECT @EmailGroup = NULL
If @PL_Desc is Null Or @PL_Desc = ''
  Begin
 	 Select 'Production Line Missing'
 	 Return(-100)
  End
If @PU_Desc is Null Or @PU_Desc = ''
  Begin
 	 Select 'Production Unit Missing'
 	 Return(-100)
  End
If @Var_Desc is Null Or @Var_Desc = ''
  Begin
 	 Select 'Variable Missing'
 	 Return(-100)
  End
Select @PL_Id = PL_Id From Prod_Lines
       Where PL_Desc = @PL_Desc
If @PL_Id Is Null
  Begin
 	 Select 'Failed - Production Line Not Found'
 	 Return(-100)
  End
Select @PU_Id = PU_Id From Prod_Units
    Where PU_Desc = @PU_Desc And PL_Id = @PL_Id
If @PU_Id Is Null
  Begin
 	 Select 'Failed - Production Unit Not Found'
 	 Return(-100)
  End
Select @Var_Id = Var_Id From Variables
   Where Var_Desc = @Var_Desc And PU_Id = @PU_Id
If @Var_Id Is Null
  Begin
 	 Select 'Failed - Variable Not Found'
    Return (-100)
  End
If @AT_Desc Is Null or @AT_Desc = ''
  Begin
 	 Select 'Failed - Alarm Template Name Missing'
 	 Return (-100)
  End
Select @AT_Id = AT_Id  From Alarm_Templates
     Where AT_Desc = @AT_Desc
If @AT_Id Is Null
  Begin
 	 Select 'Failed - Alarm Template not found'
 	 Return (-100)
  End
If @EmailGroup IS Not NULL
BEGIN
 	 Select @EGId = EG_Id 
 	  	 from Email_Groups 
 	  	 where EG_Desc = @EmailGroup
 	 IF @EGId IS Null
 	 BEGIN
 	  	 Select 'Failed - E-Mail Group not found'
 	  	 Return(-100)
 	 END
END
ELSE
BEGIN
 	 Select @EGId = Null
END
/******************************************************************************************************************************************************
*  	  	  	  	 Insert Alarm Template Variable Assignment 	  	  	  	  	 *
******************************************************************************************************************************************************/
  Select @ATD_Id = ATD_Id
     From Alarm_Template_Var_Data
     Where AT_Id = @AT_Id And Var_Id = @Var_Id
  If @ATD_Id Is Null
 	 Begin
      Execute spEMAC_AddAttachedVariables @AT_Id,@Var_Id,@EGId,@User_Id  
   	   Select @ATD_Id = ATD_Id From Alarm_Template_Var_Data
       Where AT_Id = @AT_Id And Var_Id = @Var_Id
      If @ATD_Id Is Null
 	  	 Begin
 	  	   Select 'Failed - Unable to link variable'
 	  	   Return (-100)
 	  	 End
    End
RETURN(0)
