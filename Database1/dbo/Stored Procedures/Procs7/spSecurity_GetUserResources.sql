
CREATE PROCEDURE dbo.spSecurity_GetUserResources

@GroupIds nvarchar(max) ,				/* user group ids				*/
@PermissionName nvarchar(max)			/* permission name				*/

--@returnMessage nvarchar(100)

AS
CREATE TABLE #GroupIds(G_Id nvarchar(4000))
CREATE TABLE #GroupIdsFilterResource1(permission_id int ,permission_name nvarchar(max),line_id int, units_id int, department_id int)


DECLARE @SQLStr nvarchar(max)
DECLARE @delimiter as nVarChar(10)
DECLARE @xmls as xml
Declare @returnstatus nvarchar(1000)
Declare @TotalsizeInput int
Declare @check int
Declare @check1 int

if (@GroupIds is not null)
		Begin
			SET @delimiter =','
			SET @xmls = cast(('<X>'+replace(@GroupIds,@delimiter ,'</X><X>')+'</X>') as xml)
			INSERT INTO #GroupIds (G_Id)  
			SELECT N.value('.', 'nvarchar(max)') as value FROM @xmls.nodes('X') as T(N)
		End

insert into #GroupIdsFilterResource1 (permission_id ,permission_name ,line_id,units_id,department_id)
SELECT distinct p.id as permission_id, p.scope as permission_name , line_id  , units_id , department_id FROM security.Assignments a 
inner join security.Assignment_Role_Details ard on ard.assignment_id = a.id 
inner join security.Role_Details rd on rd.role_id = ard.role_id 
inner join security.Assignment_Group_Details agd on agd.assignment_id = a.id and agd.group_id in (select G_Id from #GroupIds)
inner join security.Permissions p on p.id = rd.permission_id 
left join security.Line_Resource_Details lrd on lrd.assignment_id = a.id 
left join security.Units_Resource_Details urd on urd.assignment_id = a.id 
left join security.Department_Resource_Details drd on drd.assignment_id = a.id 
where p.scope = @PermissionName

select @check = count(*) from #GroupIdsFilterResource1

if(@check = 0)
begin
	select Error = 'Resources not found on this permission'
end
else
	begin
		select permission_id ,permission_name ,line_id,units_id,department_id from #GroupIdsFilterResource1
	end

