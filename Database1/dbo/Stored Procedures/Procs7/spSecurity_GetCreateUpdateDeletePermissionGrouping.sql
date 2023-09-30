
CREATE PROCEDURE [dbo].[spSecurity_GetCreateUpdateDeletePermissionGrouping]
@paramType    nVarChar(10) = null,					/*		param type				*/
@Name  nVarchar(25) = null,							/*		name					*/
@Description  nvarchar(50) = null,					/*		description				*/
@Created_by    nvarchar(max) = null,					/*		created by				*/
@CreatedDate datetime2 = null,						/*		created date			*/
@ModifiedBy  nvarchar(max) = null,					/*		modified by				*/
@ModifiedDate datetime2 = null,						/*		modified date			*/
@Id int  = null										/*		permission grouping id	*/
   AS
BEGIN TRANSACTION
DECLARE @AId Int; 
Declare @chck int;
Declare @TempId int;
DECLARE @Name_Check nVarchar(25)
Declare @chckError int;
-- Create Permission grouping
 IF(@paramType ='INSERT')
    BEGIN
		IF @Name IS NOT NULL
			 begin
				  select @TempId = id FROM security.Permissions_Grouping WHERE name = @Name
					if @TempId is null
						begin
							INSERT INTO security.Permissions_Grouping(name,description,created_by,created_date,modified_by,modified_date)
								VALUES(@Name,@Description,@Created_by,@CreatedDate,@ModifiedBy,@ModifiedDate)
				
							Select @AId = CAST(Scope_Identity() AS int)
						
							SELECT id,name,description,created_by,created_date,modified_by,modified_date FROM security.Permissions_Grouping pg WHERE pg.id = @AId 
						end
						else
							BEGIN
			 	  				SELECT Error = 'Permission grouping name already exists','ESS1033' as Code			
							END		
					 end
			end
-- Update Permission grouping
 IF(@paramType ='UPDATE')
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM security.Permissions_Grouping pg WHERE pg.id = @Id) and  @Id is not Null
			 	BEGIN
					select @chckError = 1
			 	  	SELECT Error = 'Permission group id not found','ESS1034' as Code
			 	END
		else
			begin
				IF @chckError IS NULL
					BEGIN
								 select @TempId = id FROM security.Permissions_Grouping WHERE name = @Name
								 if (@TempId = @Id) or (@TempId is null)
										begin
													update security.Permissions_Grouping set name=@Name,
													description = @Description,
													modified_by = @ModifiedBy,
													modified_date = @ModifiedDate
													where id =@Id;
													SELECT id,name,description,created_by,created_date,modified_by,modified_date FROM security.Permissions_Grouping pg WHERE pg.id = @Id
										end
								else
									if @chckError is null
											BEGIN
												select @chckError =1
			 	  								SELECT Error = 'Permission grouping name already exists','ESS1035' as Code			
											END
								end
				end
	END
-- Delete Permission grouping
 IF(@paramType='DELETE')
    BEGIN
		   
			  IF @Id is Null
			 	 BEGIN
					select @chck =1
			 	  	  SELECT Error = 'Permissions_Grouping id required to delete','ESS1036' as Code					  
			 	 END
			 	 
			  IF NOT EXISTS(SELECT 1 FROM security.Permissions_Grouping WHERE id = @Id) and  @Id is not Null
			 	 BEGIN
				 select @chck =1
			 	  	 SELECT Error = 'Permissions_Grouping id not found to delete','ESS1037' as Code					 
			 	 END
			IF NOT EXISTS(SELECT 1 FROM security.Permission_Group_Details WHERE permission_group_id = @Id) and  @Id is not Null
				BEGIN
					IF @chck is null
						begin
		 					 delete from security.Permission_Group_Details where permission_group_id = @Id
							 delete from security.Permissions_Grouping where id = @Id
							 SELECT Success = 'Permissions grouping deleted successfully'
						end		
				END
			ELSE
				BEGIN
					 select @TempId = permission_group_id FROM security.Permission_Group_Details WHERE permission_group_id = @Id
			 	  	 select @Name_Check  =  name FROM security.[Permissions] WHERE id in (@TempId)
					 if @Name_Check is not null
						BEGIN
							SELECT Error = 'Permissions grouping is already used in Permission can''t be deleted.','ESS1038' as Code
						END	
				END
			  	 
	END
	
COMMIT TRANSACTION;
