
CREATE PROCEDURE [dbo].[spSecurity_GetPermissions]
@paramType    nVarChar(10) = null,				/*		Operation type					 */
@PermissionId int  = null,						/*		Permission id					 */
@PageNumber INT = NULL,							/*		Current page number				 */
@PageSize INT  = NULL,							/*		Total records per page to display*/
@isAppPermissions  bit = null				    /*		include app permissions	in response	 */

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

-- get all permissions 
 IF(@paramType ='All')
    BEGIN
		SET @SQLStr =  '
				;With S as (SELECT  distinct p.id , p.name , p.description, p.scope ,p.created_by ,p.created_date,p.modified_by ,p.modified_date, pf.name as app_name ,pf.id as app_id,p.is_app_permission 					
							  FROM security.Permissions p
							  left join security.Permission_Group_Details pgd on pgd.permission_id = p.id
							  Left join security.Permissions_Grouping pf on pf.id = pgd.Permission_group_id'
						
					IF @isAppPermissions is not Null	
					 BEGIN  
						SET @SQLStr =  @SQLStr + ' where p.is_app_permission ='+cast(@isAppPermissions as nvarchar)
					 END

		SET @SQLStr =  @SQLStr + '
				),S1 as (Select count(0)Total from S)
				  Select *,(Select Total from S1)totalRecords from S'
		SET @SQLStr =  @SQLStr + '
				order by id 
				OFFSET '+cast(@StartPosition as nvarchar)+' ROWS
				FETCH NEXT '+cast(@PageSize as nvarchar)+' ROWS ONLY;'

		EXEC (@SQLStr)							  
	END
	
--get permission by id
IF(@paramType ='GET_BY_ID')
    BEGIN
			 IF @PermissionId is Null
			 	 BEGIN
					select @chck =1
			 	  	SELECT Error = 'Permission Id required' ,Error_Code='E004'
  			 	 END
			 	 
			  IF NOT EXISTS(SELECT 1 FROM security.Permissions WHERE id = @PermissionId) and  @PermissionId is not Null
			 	 BEGIN
					select @chck =1
			 	  	SELECT Error = 'Permission Id is not found'	,Error_Code='E004'		 
			 	 END

			  IF @PermissionId is Not Null And @chck is null
				begin
					SELECT  distinct p.id , p.name , p.description, p.scope ,p.created_by ,p.created_date,p.modified_by ,p.modified_date, pf.name as app_name ,pf.id as app_id							
							  ,totalRecords=1,p.is_app_permission FROM security.Permissions p
							  left join security.Permission_Group_Details pgd on pgd.permission_id = p.id
							  Left join security.Permissions_Grouping pf on pf.id = pgd.Permission_group_id 
							  where p.id = @PermissionId
				end
		
	END	





