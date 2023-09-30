
CREATE PROCEDURE [dbo].[spSecurity_GetCreateUpdateDeleteRoles]
@paramType    nVarChar(10) = null,					/*		param type			*/
@Name  nVarchar(25) = null,							/*		name				*/
@Description  nvarchar(50) = null,					/*		description			*/
@LineIds nvarchar(max) = null,						/*		line id's			*/
@Created_by    nvarchar(max) = null,					/*		created by			*/
@CreatedDate datetime2 = null,						/*		created date		*/
@ModifiedBy  nvarchar(max) = null,					/*		modified by			*/
@ModifiedDate datetime2 = null,						/*		modified date		*/
@RoleId int  = null									/*		rold id				*/

   AS

BEGIN TRANSACTION
CREATE TABLE #PermissionIds(P_Id Int)
CREATE TABLE #LineIds(L_Id Int)



CREATE TABLE #RoleTemp(
[id] [int],
	[name] [nvarchar](255),
	[description] [nvarchar](255),
	[created_by] [nvarchar](255) ,
	[created_date] [datetime2](7) ,
	[modified_by] [nvarchar](255) ,
	[modified_date] [datetime2](7) ,
)

DECLARE @OldFamilyId int
DECLARE @OldProdCode nVarchar(25)
DECLARE @AId Int; 
DECLARE @xml XML
Declare @chck int;
Declare @TempId int;
Declare @TotalsizeInput int;
Declare @TotalsizePermissions int;
DECLARE @Name_Check nVarchar(25)
Declare @chckError int;
 
 begin
if (@LineIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@LineIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #LineIds (L_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End
end
		
-- Create Products
 IF(@paramType ='INSERT')
    BEGIN
	
		IF @Name IS NOT NULL
			begin 
			select @TotalsizeInput = count(*) from #LineIds

			select @TotalsizePermissions =  count(*) from security.Permissions where id in (select * from #LineIds)
			if @TotalsizeInput = @TotalsizePermissions
			 begin
			  
				  select @TempId = id FROM security.Role_Base WHERE name = @Name
					if @TempId is null
						begin
							INSERT INTO security.Role_Base(name,description,created_by,created_date,modified_by,modified_date)
								VALUES(@Name,@Description,@Created_by,@CreatedDate,@ModifiedBy,@ModifiedDate)
				
							Select @AId = CAST(Scope_Identity() AS int)
							if @LineIds is not null
								begin
									INSERT INTO security.Role_Details (role_id,permission_id) select @AId, L_Id from #LineIds
								end
							SELECT  distinct ps.id , ps.name as roleName, ps.description,p.name as permissionName 
											,p.id as permission_id,p.description as permission_description 
											,role_id , p.scope ,ps.created_by,ps.created_date,ps.modified_by,ps.modified_date,totalRecords=0
											 FROM security.Role_Base ps
											 Left join security.Role_Details psd on psd.role_id = ps.id 
											 Left join security.Permissions p on p.id = psd.permission_id 
											 left join security.Permission_Group_Details pgd on pgd.permission_id = psd.permission_id
											 Left join security.Permissions_Grouping pf on pf.id = pgd.Permission_group_id	
											 where ps.id = @AId
						end
						else
							BEGIN
			 	  				SELECT Error = 'Role Name already exists','ESS1039' as Code
							END		

					 end
			 else
			  begin
				 SELECT Error = 'Permission ids not found','ESS1040' as Code
			  end
			end
	END

	-- Update Products
 IF(@paramType='UPDATE')

	BEGIN

	IF @Name is not Null
	 BEGIN

				IF NOT EXISTS(SELECT 1 FROM security.Role_Base WHERE id = @RoleId) and  @RoleId is not Null
			 	 BEGIN
				 select @chckError =1
			 	  	 SELECT Error = 'Role id not found','ESS1041' as Code
					 
			 	 END

			select @TotalsizeInput = count(*) from #LineIds
			select @TotalsizePermissions =  count(*) from security.Permissions where id in (select * from #LineIds)
			if (@TotalsizeInput = @TotalsizePermissions)
			 begin

						 select @TempId = id FROM security.Role_Base WHERE name = @Name

						 if (@TempId = @RoleId) or (@TempId is null)
								begin
									INSERT INTO #RoleTemp (id,name,description,created_by,created_date,modified_by,modified_date)  
											SELECT * from security.Role_Base where id=@RoleId
									select @chck = id from #RoleTemp
						
									if @chck is not null
										 begin
											update security.Role_Base set name=@Name,
											description = @Description,
											modified_by = @ModifiedBy,
											modified_date = @ModifiedDate

											where id =@RoleId;

											delete from security.Role_Details where role_id in (@RoleId);
							
											if @LineIds is not null
											begin
												INSERT INTO security.Role_Details (role_id,permission_id) select @RoleId, L_Id from #LineIds
											end
			
											SELECT  distinct ps.id , ps.name as roleName, ps.description,p.name as permissionName 
											,p.id as permission_id,p.description as permission_description 
											,role_id , p.scope ,ps.created_by,ps.created_date,ps.modified_by,ps.modified_date,totalRecords=0
											 FROM security.Role_Base ps
											 Left join security.Role_Details psd on psd.role_id = ps.id 
											 Left join security.Permissions p on p.id = psd.permission_id 
											 left join security.Permission_Group_Details pgd on pgd.permission_id = psd.permission_id
											 Left join security.Permissions_Grouping pf on pf.id = pgd.Permission_group_id	
											 where ps.id = @RoleId
												
 
										 end 
								end

					

						else
							if @chckError is null
									BEGIN
									select @chckError =1
			 	  						SELECT Error = 'Role Name already exists','ESS1042' as Code			
									END
				end
				else
				  begin
					 SELECT Error = 'Permission ids not found','ESS1040' as Code			
				  end

		end			 
			 	 	 

	
	
	end
	
IF(@paramType ='ALL_APPS')
    BEGIN
    
		SELECT pg.id as pg_id,pg.name as app_name ,pg.description as app_desc , p.id as p_id , 
			 p.name as permission_name ,p.description ,p.scope 
			 FROM security.Permissions_Grouping pg 
			 left join security.Permission_Group_Details pgd on pgd.permission_group_id = pg.id
			 left join security.Permissions p on p.id = pgd.permission_id 
			 
	END




	
-- Delete Products
 IF(@paramType='DELETE')
    BEGIN
		   
			  IF @RoleId is Null
			 	 BEGIN
					select @chck =1
			 	  	  SELECT Error = 'Role id required to delete','ESS1044' as Code
			 	 END
			 	 
			  IF NOT EXISTS(SELECT 1 FROM security.Role_Base WHERE id = @RoleId) and  @RoleId is not Null
			 	 BEGIN
				 select @chck =1
			 	  	 SELECT Error = 'Role id not found to delete','ESS1045' as Code
			 	 END

			IF NOT EXISTS(SELECT 1 FROM security.Assignment_Role_Details WHERE role_id = @RoleId) and  @RoleId is not Null
				BEGIN
					IF @RoleId is Not Null And @chck is null
						begin
		 					 delete from security.Role_Details where role_id = @RoleId
							 delete from security.Role_Base where id = @RoleId
							 SELECT Success = 'Role deleted successfully'
						end		
				END
			ELSE
				BEGIN
					 select @TempId = assignment_id FROM security.Assignment_Role_Details WHERE role_id = @RoleId
			 	  	 select @Name_Check  =  name FROM security.[Assignments] WHERE id in (@TempId)
					 SELECT Error = 'Role is already assigned in assignment can''t be deleted.','ESS1046' as Code
				END

			  	 
	END

	
COMMIT TRANSACTION;
