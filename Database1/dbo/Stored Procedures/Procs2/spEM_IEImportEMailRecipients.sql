CREATE PROCEDURE dbo.spEM_IEImportEMailRecipients
 	 @EG_Desc 	  	 nVarChar(100),
 	 @ER_Desc 	  	 nVarChar(100),
 	 @ER_Address 	  	 Varchar(70),
 	 @User_Id 	  	 int
AS
Declare 	 @EG_Id int,
 	  	     @ER_Id int,
        @EGR_Id int
Select @EG_Id = Null
Select @ER_Id = Null
Select @EGR_Id = Null
------------------------------------------------------------------------------------------
-- Trim Parameters
------------------------------------------------------------------------------------------
Select @EG_Desc = LTrim(RTrim(@EG_Desc))
Select @ER_Desc = LTrim(RTrim(@ER_Desc))
Select @ER_Address = LTrim(RTrim(@ER_Address))
IF  @EG_Desc = '' SELECT @EG_Desc = Null
IF  @ER_Desc = '' SELECT @ER_Desc = Null
IF  @ER_Address = '' SELECT @ER_Address = Null
-- Verify Arguments 
If @ER_Desc IS NULL
 BEGIN
   Select 'Failed - E-Mail Recipient is Missing'
   Return(-100)
 END
------------------------------------------------------------------------------------------
--Insert or Update E-Mail Recipients
------------------------------------------------------------------------------------------
Select @ER_Id = ER_Id 
  from Email_Recipients 
  where ER_Desc = @ER_Desc --and ER_Address = @ER_Address
If @ER_Id is NULL
BEGIN
 	 exec spEM_CreateEMailRecip @ER_Desc, @User_Id, @ER_Id OUTPUT
 	 IF @ER_Id Is NULL
 	 BEGIN
 	  	 SELECT 'Failed - Unable to create E-Mail Recipient'
 	  	 Return(-100)
 	 END
 	 exec spEM_PutEmailRecipientAddress @ER_Id, @ER_Address, 1,0, @User_Id
END
ELSE
BEGIN
 	 exec spEM_PutEmailRecipientAddress @ER_Id, @ER_Address, 1,0, @User_Id
END
IF @EG_Desc IS NOT Null
BEGIN
 	 Select @EG_Id = EG_Id 
 	  	 from Email_Groups 
 	  	 where EG_Desc = @EG_Desc
 	 If @EG_Id is NULL
 	  	 exec spEM_CreateEMailGroup @EG_Desc, @User_Id, @EG_Id OUTPUT
 	 If (Select count(*) from Email_Groups_Data Where EG_Id = @EG_Id and ER_Id = @ER_Id) = 0
 	  	 exec spEM_CreateEmailMember @EG_Id, @ER_Id, @User_Id, @EGR_Id OUTPUT
END
Return(0)
