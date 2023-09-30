
CREATE PROCEDURE [dbo].[spSecurity_GetPermissionGrouping]
@paramType    nVarChar(10) = null,				/*		param type						 */
@Id int  = null									/*		permission grouping id			 */					

   AS

CREATE TABLE #PermissionIds(P_Id Int)
CREATE TABLE #LineIds(L_Id Int)




DECLARE @OldFamilyId int
DECLARE @OldProdCode nVarchar(25)
DECLARE @AId Int; 
DECLARE @xml XML
Declare @chck int;

DECLARE @SQLStr nvarchar(max)


		

-- Get all permission groupings 
 IF(@paramType ='All')
    BEGIN
		SET @SQLStr =  'SELECT DISTINCT id,name,description,created_by,created_date,modified_by,modified_date FROM security.Permissions_Grouping '
					

		EXEC (@SQLStr)

	END
	
--Get permission grouping by id
IF(@paramType ='GET_BY_ID')
    BEGIN
			 IF @Id is Null
			 	 BEGIN
					select @chck =1
			 	  	SELECT Error = 'Permission grouping id required','ESS1047' as Code
  			 	 END
			 	 
			  IF NOT EXISTS(SELECT 1 FROM security.Permissions_Grouping WHERE id = @Id) and  @Id is not Null
			 	 BEGIN
					select @chck =1
			 	  	SELECT Error = 'Permissions grouping id is not found','ESS1048' as Code					 
			 	 END

			  IF @Id is Not Null And @chck is null
				begin
					SELECT  distinct id,name,description,created_by,created_date,modified_by,modified_date FROM security.Permissions_Grouping where id = @Id
				end
		
	END	


