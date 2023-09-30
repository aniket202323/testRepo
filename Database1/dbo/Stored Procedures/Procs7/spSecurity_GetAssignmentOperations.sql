
CREATE PROCEDURE dbo.spSecurity_GetAssignmentOperations

@AssinmentId int			/* Assinment Id for search */

AS
CREATE TABLE #GroupNames(G_Id nvarchar(4000))

DECLARE @Tablevar TABLE
(
 permission_id INT
)
DECLARE @SQLStr nvarchar(max)
DECLARE @delimiter as nVarChar(10)
DECLARE @xmls as xml
Declare @returnstatus nvarchar(1000)
Declare @chck int

SET @SQLStr =  '
;With S as (
SELECT DISTINCT a.id as assignment_id ,a.name,a.description,a.created_by,a.created_date,a.modified_by,a.modified_date,agd.group_id ,ard.role_id,lrd.line_id ,
urd.units_id ,pfrd.product_family_id ,prd.product_id ,drd.department_id, srd.site_id FROM security.Assignments a 
left join [security].[Assignment_Group_Details] agd on agd.assignment_id = a.id 
left join [security].[Assignment_Role_Details] ard on ard.assignment_id = a.id 
left join [security].[Line_Resource_Details] lrd on lrd.assignment_id = a.id 
left join [security].[Units_Resource_Details] urd on urd.assignment_id = a.id 
left join [security].[Product_Family_Resource_Details] pfrd on pfrd.assignment_id = a.id 
left join [security].[Product_Resource_Details] prd on prd.assignment_id = a.id 
left join [security].[Department_Resource_Details] drd on drd.assignment_id = a.id 
left join [security].[Site_Resource_Details] srd on srd.assignment_id = a.id '

SET @SQLStr = @SQLStr + ' where a.id='+ Cast(@AssinmentId as nvarchar)

SET @SQLStr =  @SQLStr + '
) select * from S'


IF @AssinmentId is Null
	 BEGIN
		select @chck =1
 	  	SELECT Error = 'Assignment id required','ESS1029' as Code
 	 END
			 	 
IF NOT EXISTS(SELECT 1 FROM security.Assignments WHERE id = @AssinmentId) and  @AssinmentId is not Null
 	 BEGIN
		select @chck =1
 	  	SELECT Error = 'Assignment Id not found','ESS1021' as Code					 
 	 END

	 print @SQLStr
if @chck is null
	begin
		Exec(@SQLStr)
	end



