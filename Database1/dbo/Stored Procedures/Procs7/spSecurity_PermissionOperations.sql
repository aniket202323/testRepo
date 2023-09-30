
CREATE PROCEDURE [dbo].[spSecurity_PermissionOperations]
@paramType    nVarChar(10) = null,				/*		param type			*/
@Name  nVarchar(25) = null,						/*		name				*/
@Description  nvarchar(50) = null,				/*		description			*/
@Scope nvarchar(max) = null,						/*		scope				*/
@Created_by    nvarchar(max) = null,				/*		created by			*/
@CreatedDate datetime2 = null,					/*		created date		*/
@ModifiedBy  nvarchar(max) = null,				/*		modified by			*/
@ModifiedDate datetime2 = null,					/*		modified date		*/
@PermissionId int  = null,						/*		permission id		*/
@isAppPermission int = 0						/*		permission - app or core		*/

   AS

BEGIN TRANSACTION
CREATE TABLE #PermissionIds(P_Id Int)
CREATE TABLE #GroupingIds(G_Id Int)

DECLARE @AId Int; 
DECLARE @xml XML
Declare @chck int;
Declare @TempIdOne int;
Declare @TempIdTwo int;

Declare @TotalsizeInput int;
Declare @TotalsizePermissions int;

Declare @chckError int;


		
 --create Permission
 IF(@paramType ='INSERT')
    BEGIN
	
		IF @Name IS NOT NULL 
			begin 
		
				  select @TempIdOne = id FROM security.Permissions WHERE name = @Name
				  select @TempIdTwo = id FROM security.Permissions WHERE scope = @Scope
					if @TempIdOne is null and @TempIdTwo is null
						begin
							INSERT INTO security.Permissions(name,description,scope,created_by,created_date,modified_by,modified_date,is_app_permission)
								VALUES (@Name,@Description,@Scope,@Created_by,@CreatedDate,@ModifiedBy,@ModifiedDate,@isAppPermission)

							Select @AId = CAST(Scope_Identity() AS int)
							
									
							SELECT  distinct p.id , p.name , p.description, p.scope ,p.created_by ,p.created_date,p.modified_by ,p.modified_date, pf.name as app_name ,pf.id as app_id,						
							 p.is_app_permission ,totalRecords=1 FROM security.Permissions p
							  left join security.Permission_Group_Details pgd on pgd.permission_id = p.id
							  Left join security.Permissions_Grouping pf on pf.id = pgd.Permission_group_id
							  WHERE p.id = @AId

						END
						else
							if @TempIdOne is not null
							BEGIN
								select @chckError =1
			 	  				SELECT Error = 'Permission name already exists', Error_Code='E001'		
							END		
							if @TempIdTwo is not null and @chckError is null
							BEGIN
			 	  				SELECT Error = 'Permission scope already exists', Error_Code='E002'
							END		

					 end
			 
			
	END

	-- Update Permissions
 IF(@paramType='UPDATE')
   BEGIN
	select @Chck = id FROM security.Permissions WHERE id in (@PermissionId)
	if @Chck is not null
		begin
			IF @Name IS NOT NULL 
				begin 
				select @TempIdTwo = id FROM security.Permissions WHERE scope = @Scope and id not in (@PermissionId)

			
					  select @TempIdOne = id FROM security.Permissions WHERE name = @Name and id not in (@PermissionId)
					  select @TempIdTwo = id FROM security.Permissions WHERE scope = @Scope and id not in (@PermissionId)
						if @TempIdOne is null and @TempIdTwo is null
							begin
		
								update security.Permissions set name=@Name,
												description = @Description,
												scope = @Scope,											
												modified_by = @ModifiedBy,
												modified_date = @ModifiedDate,
												is_app_permission= @isAppPermission
												where id =@PermissionId



								SELECT  distinct p.id , p.name , p.description, p.scope ,p.created_by ,p.created_date,p.modified_by ,p.modified_date, pf.name as app_name ,pf.id as app_id,							
								p.is_app_permission ,totalRecords=1 FROM security.Permissions p
								left join security.Permission_Group_Details pgd on pgd.permission_id = p.id
								Left join security.Permissions_Grouping pf on pf.id = pgd.Permission_group_id
								WHERE p.id = @PermissionId 

							end
							else
								if @TempIdOne is not null
								BEGIN
									select @chckError =1;
			 	  					SELECT Error = 'Permission Name already exists', Error_Code='E001'		
								END		
								if @TempIdTwo is not null and @chckError is null
								BEGIN
									select @chckError =1;
			 	  					SELECT Error = 'Permission scope already exists', Error_Code='E002'	
								END		

						 end
				 
				end
		if @Chck is null 
		begin
			SELECT Error = 'permission id not exist' , Error_Code='E004'		
		end
	end



	
	
-- Delete Permissions
 IF(@paramType='DELETE')
    BEGIN
		   
			  IF @PermissionId is Null
			 	 BEGIN
					select @chck =1
			 	  	  SELECT Error = 'Permission id required to delete'	, Error_Code='E005'				  
			 	 END
			
			  IF NOT EXISTS(SELECT 1 FROM security.permissions WHERE id = @PermissionId) and  @PermissionId is not Null
			 	 BEGIN
				 select @chck =1
			 	  	 SELECT Error = 'Permission id not found to delete', Error_Code='E006'			 
			 	 END

			  IF @PermissionId is Not Null And @chck is null
				begin
		 			 delete from security.Permission_Group_Details where permission_id =  @PermissionId
					 delete from security.permissions where id = @PermissionId
					 SELECT Success = 'Permission deleted successfully'
				end			 
	END

	
COMMIT TRANSACTION;
