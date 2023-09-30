CREATE PROCEDURE dbo.spSecurity_GetAllAssignmentOperations

@PageNumber INT = NULL,					/*		Current page number					*/
@PageSize INT  = NULL,					/*		Total records per page to display	*/
@paramType nVarChar(10) = null,
@GroupID    nvarchar(max) = null

AS

DECLARE @SQLStr nvarchar(max)

 IF(@paramType ='ALL')
 BEGIN

DECLARE @Tablevar TABLE
(
 permission_id INT
)

DECLARE @Site nvarchar(10)='Site'
DECLARE @delimiter as nVarChar(10)
DECLARE @xmls as xml
Declare @returnstatus nvarchar(1000)

DECLARE @StartPosition INT= @PageSize * (@PageNumber - 1);

SET @SQLStr =  '
;With S as (
SELECT DISTINCT a.id as assignment_id ,a.name,a.description,a.created_by,a.created_date,a.modified_by,a.modified_date FROM security.Assignments a '

SET @SQLStr =  @SQLStr + '
				),S1 as (Select count(0)Total from S)
				  Select *,(Select Total from S1)totalRecords from S'
		SET @SQLStr =  @SQLStr + '
				order by assignment_id 
				OFFSET '+cast(@StartPosition as nvarchar)+' ROWS
				FETCH NEXT '+cast(@PageSize as nvarchar)+' ROWS ONLY;'
		
		EXEC (@SQLStr)

END

 IF(@paramType ='BY_GROUP')
 BEGIN



SET @SQLStr =  '
;With S as (
SELECT  a.id as assignmentId ,a.name,a.description,
agd.group_id groupId,ard.role_id roleId,lrd.line_id lineId,
urd.units_id unitId
--,pfrd.product_family_id ,prd.product_id 
,drd.department_id departmentId, srd.site_id siteId,
pub.PU_Desc Unit, plb.PL_Desc Line, depb.Dept_Desc Dept, rb.name roleName,
CASE
    WHEN srd.site_id is not null THEN ''Plant''
END AS siteName
FROM security.Assignments a 
left join [security].[Assignment_Group_Details] agd on agd.assignment_id = a.id 
left join [security].[Assignment_Role_Details] ard on ard.assignment_id = a.id 
left join [security].[Line_Resource_Details] lrd on lrd.assignment_id = a.id 
left join [security].[Units_Resource_Details] urd on urd.assignment_id = a.id 
--left join [security].[Product_Family_Resource_Details] pfrd on pfrd.assignment_id = a.id 
--left join [security].[Product_Resource_Details] prd on prd.assignment_id = a.id 
left join [security].[Department_Resource_Details] drd on drd.assignment_id = a.id 
left join [security].[Site_Resource_Details] srd on srd.assignment_id = a.id 
left join prod_units_base pub on urd.units_id =pub.PU_Id
left join Prod_Lines_Base plb on plb.PL_Id =lrd.line_id
left join Departments_Base depb on depb.Dept_id= drd.department_id
left join [security].Role_Base rb on rb.id= ard.role_id'

 IF(@GroupId is not null)
 BEGIN
SET @SQLStr = @SQLStr + ' where agd.group_id = '''+ cast(@GroupId as nvarchar(max))
SET @SQLStr = @SQLStr +  ''''
END
SET @SQLStr = @SQLStr + ' ) select * from S order by S.assignmentId'

print @SQLStr

Exec(@SQLStr)
 END
