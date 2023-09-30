
CREATE PROCEDURE [dbo].[spSecurity_PermissionGroupMapping]
@paramType    nVarChar(10) = null,				/*		param type			*/
@GroupingIds nvarchar(max) = null,				/*		grouping ids		*/
@PermissionId int  = null,						/*		permission id		*/
@GroupingId int = null						   /*  group id  */
   AS

BEGIN TRANSACTION
CREATE TABLE #TempGroupIds(G_Id Int)
CREATE TABLE #GroupingIds(G_Id Int)



DECLARE @AId Int; 
DECLARE @xml XML
Declare @chck int;
Declare @TempIdOne int;
Declare @TempIdTwo int;
DECLARE @SQLStr nvarchar(max)

Declare @TotalsizeInput int;
Declare @TotalsizePermissions int;

Declare @chckError int;

 
 begin
if (@GroupingIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@GroupingIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #GroupingIds (G_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End
end
		
 --create Permission
 IF(@paramType ='INSERT')
    BEGIN
	
		IF @PermissionId IS NOT NULL 
			begin 
			select @TotalsizeInput = count(*) from #GroupingIds
			select @TotalsizePermissions =  count(*) from security.Permissions_Grouping where id in (select * from #GroupingIds)
			
			INSERT INTO #TempGroupIds (G_Id)  select distinct permission_group_id from security.Permission_Group_Details where permission_group_id in (select * from #GroupingIds) and permission_id = @PermissionId;



			 if @TotalsizeInput = @TotalsizePermissions
			 begin 
						
							if @GroupingIds is not null
								begin
									INSERT INTO security.Permission_Group_Details (permission_id ,permission_group_id) select @PermissionId, G_Id from #GroupingIds gi where gi.G_Id not in (select G_Id from #TempGroupIds);
								end
							
							SELECT  distinct p.id , p.name , p.description, p.scope ,p.created_by ,p.created_date,p.modified_by ,p.modified_date, pf.name as app_name ,pf.id as app_id							
							  ,p.is_app_permission, totalRecords=1 FROM security.Permissions p
							  left join security.Permission_Group_Details pgd on pgd.permission_id = p.id
							  Left join security.Permissions_Grouping pf on pf.id = pgd.Permission_group_id
							  WHERE p.id = @PermissionId and pf.id in (select * from #GroupingIds)

					 end
			 else
			  begin
				 SELECT Error = 'Group ids not exist', Error_Code='E003'	
			  end
			end
	END

	 --get Permission
 IF(@paramType ='GETALL')
    BEGIN



			SET @SQLStr =  '
		;With S as (
		SELECT  distinct p.id , p.name , p.description, p.scope ,p.created_by ,p.created_date,p.modified_by ,p.modified_date, pf.name as app_name ,pf.id as app_id							
							  ,p.is_app_permission,totalRecords=1 FROM security.Permissions p
							  left join security.Permission_Group_Details pgd on pgd.permission_id = p.id
							  Left join security.Permissions_Grouping pf on pf.id = pgd.Permission_group_id
		  where 1=1 '
		
		IF (@PermissionId IS NOT NULL)
			BEGIN
			
			  SET @SQLStr = @SQLStr + ' and p.id='+ Cast(@PermissionId as nvarchar)
			 		
			END
			
	   IF (@GroupingId IS NOT NULL)
			BEGIN
			   SET @SQLStr = @SQLStr + ' and pf.id='+ Cast(@GroupingId as nvarchar)
			
			END
			
		SET @SQLStr =  @SQLStr + '
		) select * from S'

		Exec(@SQLStr)

	END

-- Delete Permissions Group mapping
 IF(@paramType='DELETE')
    BEGIN
		   
			  IF @PermissionId is Null
			 	 BEGIN
					select @chck =1
			 	  	  SELECT Error = 'Permission id required to delete'	, Error_Code='E1005'				  
			 	 END

				  IF @GroupingId is Null
			 	 BEGIN
					select @chck =1
			 	  	  SELECT Error = 'Permission Group id required to delete'	, Error_Code='E1006'				  
			 	 END


			  IF NOT EXISTS(SELECT 1 FROM security.Permission_Group_Details WHERE permission_id = @PermissionId and permission_group_id=@GroupingId)
			 	 BEGIN
				 select @chck =1
			 	  	 SELECT Error = 'Permission Group mapping not found to delete', Error_Code='E1007'			 
			 	 END

			  IF @PermissionId is Not Null And @GroupingId is Not Null And @chck is null
				begin
		 			 delete from security.Permission_Group_Details where permission_id =  @PermissionId and permission_group_id=@GroupingId
					
					 SELECT Success = 'Permission group mapping deleted successfully'
				end			 
	END

	
COMMIT TRANSACTION;
