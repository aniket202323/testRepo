
CREATE PROCEDURE [dbo].[spSecurity_createUpdateDeletePermissionInclusion]
@paramType    nVarChar(10) = null,					/*	param type			*/
@appScopeId int  = null	,							/* app	permission id	*/
@coreScopeId int  = null 							/* core	permission id	*/


   AS

BEGIN TRANSACTION

DECLARE @AId Int; 
Declare @chck int;
Declare @TempId int;
Declare @chckError int;
DECLARE @SQLStr nvarchar(max);




-- Get Permission grouping
 IF(@paramType ='ALL')
    BEGIN

		SET @SQLStr =  '
		;With S as (
		SELECT DISTINCT app_permission_id, permission_id FROM security.Permission_Inclusions pi
		 right join [security].[Permissions] p on p.id =pi.app_permission_id or p.id =permission_id 
		  where 1=1 '
		
		
		IF (@appScopeId IS NOT NULL)
			BEGIN
			
			  SET @SQLStr = @SQLStr + ' and pi.app_permission_id='+ Cast(@appScopeId as nvarchar)
			 		
			END
			
	   IF (@coreScopeId IS NOT NULL)
			BEGIN
			   SET @SQLStr = @SQLStr + ' and pi.permission_id='+ Cast(@coreScopeId as nvarchar)
			
			END
			
			
		SET @SQLStr =  @SQLStr + '
		) select * from S'


		Exec(@SQLStr)
	END
		
		
-- Create Permission Inclusion
 IF(@paramType ='INSERT')
    BEGIN
    
    
    		
    IF NOT EXISTS(SELECT 1 FROM security.permissions WHERE id = @appScopeId)
		BEGIN
		select @chck =1
			SELECT Error = 'App permissions is not found','ESS3001' as Code					 
	  END
	 ELSE  IF NOT EXISTS(SELECT 1 FROM security.permissions WHERE id = @coreScopeId)
		BEGIN
		select @chck =1
			SELECT Error = 'Core permissions is not found','ESS3002' as Code					 
	  END
    ELSE  IF NOT EXISTS(SELECT 1 FROM security.permissions WHERE id = @coreScopeId and is_app_permission=0)
		BEGIN
		select @chck =1
			SELECT Error = 'Given permissions is not a core permission','ESS3003' as Code					 
	  END
	  ELSE  IF NOT EXISTS(SELECT 1 FROM security.permissions WHERE id = @appScopeId and is_app_permission=1)
		BEGIN
		select @chck =1
			SELECT Error = 'Given permissions is not a app permission','ESS3004' as Code					 
	  END
    
	  ELSE IF @appScopeId IS NOT NULL
			 begin
			 
				  select @TempId = app_permission_id FROM security.Permission_Inclusions WHERE app_permission_id = @appScopeId and permission_id =@coreScopeId
					if @TempId is null
						begin
							INSERT INTO security.Permission_Inclusions(app_permission_id,permission_id)VALUES(@appScopeId,@coreScopeId);
						
							SELECT app_permission_id,permission_id FROM security.Permission_Inclusions pi WHERE pi.app_permission_id = @appScopeId and pi.permission_id =@coreScopeId
						end
						else
							BEGIN
			 	  				SELECT Error = 'Permission Inclusion mapping already exists','ESS2033' as Code			
							END		

					 end
			end

-- Delete Permission grouping
 IF(@paramType='DELETE')
    BEGIN
     

	 IF NOT EXISTS(SELECT 1 FROM security.Permission_Inclusions WHERE app_permission_id = @appScopeId and permission_id =@coreScopeId)
		BEGIN
		select @chck =1
			SELECT Error = 'Permissions Inclusion mapping not found to delete','ESS2036' as Code					 
		END
	 else IF @appScopeId is Null
			 	 BEGIN
					select @chck =1
			 	  	  SELECT Error = 'Permissions_Inclusion app_permission_id required to delete','ESS2034' as Code					  
			 	 END
    else IF @coreScopeId is Null
				  BEGIN
					select @chck =1
			 	  	  SELECT Error = 'Permissions_Inclusion permission_id required to delete','ESS2035' as Code					  
			 	 END
			 	 
				ELSE IF @chck is null
						begin
		 					 delete from security.Permission_Inclusions where app_permission_id = @appScopeId and permission_id =@coreScopeId
							 SELECT Success = 'Permissions Inclusion mapping deleted successfully'
						end		
				
END


COMMIT TRANSACTION;
