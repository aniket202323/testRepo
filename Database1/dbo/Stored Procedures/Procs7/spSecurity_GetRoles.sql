CREATE PROCEDURE [dbo].[spSecurity_GetRoles]
@paramType    nVarChar(10) = null,				/*		param type						 */
@RoleId int  = null,							/*		role id							 */	
@PageNumber INT = NULL,							/*		Current page number				 */
@PageSize INT  = NULL							/*		Total records per page to display*/
				

   AS

CREATE TABLE #PermissionIds(P_Id Int)
CREATE TABLE #LineIds(L_Id Int)




DECLARE @OldFamilyId int
DECLARE @OldProdCode nVarchar(25)
DECLARE @AId Int; 
DECLARE @xml XML
Declare @chck int;

DECLARE @SQLStr nvarchar(max)
DECLARE @StartPosition INT= @PageSize * (@PageNumber - 1);

		

-- get all roles 
 IF(@paramType ='All')
    BEGIN
			SET @SQLStr = '
				;With S as (
				SELECT  distinct ps.id , ps.name , ps.description,ps.created_date,ps.created_by,ps.modified_by,ps.modified_date FROM security.Role_Base ps '

		SET @SQLStr =  @SQLStr + '
				),S1 as (Select count(0)Total from S)
				  Select *,(Select Total from S1)totalRecords from S '
print @SQLStr
		SET @SQLStr =  @SQLStr + '
				order by id 
				OFFSET '+cast(@StartPosition as nvarchar)+' ROWS
				FETCH NEXT '+cast(@PageSize as nvarchar)+' ROWS ONLY;'

		EXEC (@SQLStr)

	END
	
--get role by id
IF(@paramType ='GET_BY_ID')
    BEGIN
			 IF @RoleId is Null
			 	 BEGIN
					select @chck =1
			 	  	SELECT Error = 'Role Id Required','ESS1049' as Code
  			 	 END
			 	 
			  IF NOT EXISTS(SELECT 1 FROM security.Role_Base WHERE id = @RoleId) and  @RoleId is not Null
			 	 BEGIN
					select @chck =1
			 	  	SELECT Error = 'Role id not found','ESS1041' as Code					 
			 	 END

			  IF @RoleId is Not Null And @chck is null
				begin
					SELECT  distinct ps.id , ps.name as roleName, ps.description,p.name as permissionName 
							,p.id as permission_id,p.description as permission_description 
							,role_id ,p.scope ,ps.created_by,ps.created_date,ps.modified_by,ps.modified_date,totalRecords=0
							  FROM security.Role_Base ps
							  Left join security.Role_Details psd on psd.role_id = ps.id 
							  Left join security.Permissions p on p.id = psd.permission_id 
							  left join security.Permission_Group_Details pgd on pgd.permission_id = psd.permission_id
							  Left join security.Permissions_Grouping pf on pf.id = pgd.Permission_group_id 

							  where ps.id = @RoleId
				end
		
	END	


