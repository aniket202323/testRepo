CREATE procedure [dbo].[spSDK_AU_SpecTransactionGroup]
@AppUserId int,
@SpecTransactionGroup varchar(100) ,
@Id int OUTPUT
AS
IF @Id IS NULL
BEGIN
 	 IF EXISTS (SELECT 1 From Transaction_Groups  WHERE Transaction_Grp_Desc = @SpecTransactionGroup)
 	 BEGIN
 	  	 SELECT 'Add Failed - A transaction Group with same name already exists'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_CreateApprovedGroup @SpecTransactionGroup,@AppUserId,@Id Output
END
ELSE
BEGIN
 	 IF NOT EXISTS (SELECT 1 From Transaction_Groups  WHERE Transaction_Grp_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Update Failed - transaction Group Not found'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_RenameTransactionGroup  @Id,@SpecTransactionGroup,@AppUserId
END
Return(1)
