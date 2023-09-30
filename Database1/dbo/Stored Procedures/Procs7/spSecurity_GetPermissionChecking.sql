
CREATE PROCEDURE [dbo].[spSecurity_GetPermissionChecking]
@GroupNames nvarchar(max) ,				/* user group names				*/

@ResourceType nvarchar(100),				/* resource type means Line or Unit or Product or ProductFamily ... names */

@resourceId int,						/* resource type related ids	*/

@PermissionName nvarchar(max)			/* user group names				*/

--@returnMessage nvarchar(100)

AS
DECLARE @SQL NVARCHAR(MAX)='';
Declare @GroupNamesId TABLE
(G_Id nvarchar(4000))
DECLARE @GroupNamesFilterResource1 TABLE 
(line_id int, units_id int, department_id int, site_id int)
DECLARE @SQLStr nvarchar(max)
DECLARE @delimiter as nVarChar(10)
DECLARE @xmls as xml
Declare @returnstatus nvarchar(1000)
Declare @TotalsizeInput int
Declare @check int
Declare @check1 int
Declare @siteCheck int
Declare @G_Id Nvarchar(max)
Select @check =0 , @check1 = 0 ,@siteCheck=0

if (@GroupNames is not null)
		Begin
			SET @delimiter =','
			SET @xmls = cast(('<X>'+replace(@GroupNames,@delimiter ,'</X><X>')+'</X>') as xml)
			INSERT INTO @GroupNamesId (G_Id)  
			SELECT N.value('.', 'nvarchar(max)') as value FROM @xmls.nodes('X') as T(N)
		End

Select @G_Id = COALESCE(@G_Id+''',''','')+G_Id From @GroupNamesId;

SELECT @G_Id = ''''+@G_Id+''''

SELECT @SQL='
SELECT line_id  , units_id , department_id, site_id FROM security.Assignments a 
inner join [security].[Assignment_Role_Details] ard on ard.assignment_id = a.id 
inner join [security].[Role_Details] rd on rd.role_id = ard.role_id 
inner join [security].[Assignment_Group_Details] agd on agd.assignment_id = a.id and agd.group_id in ('+@G_Id+')
inner join [security].[Permissions] p on p.id in ( SELECT rd.permission_id
  UNION
  SELECT permission_id
  FROM [security].[Permission_Inclusions]
  WHERE app_permission_id = rd.permission_id) and p.scope = '''+@PermissionName+'''
left join [security].[Line_Resource_Details] lrd on lrd.assignment_id = a.id 
left join [security].[Units_Resource_Details] urd on urd.assignment_id = a.id 
left join [security].[Department_Resource_Details] drd on drd.assignment_id = a.id
left join [security].[Site_Resource_Details] srd on srd.assignment_id = a.id 
where p.scope = '''+@PermissionName+'''
'
insert into @GroupNamesFilterResource1 (line_id,units_id,department_id, site_id)
EXEC (@SQL)



--if (@ResourceType = 'Unit') or (@ResourceType = 'Line') or (@ResourceType = 'Department') or (@ResourceType = 'Site')
IF(@ResourceType IS NOT NULL)
begin
select @siteCheck = 1 from @GroupNamesFilterResource1 where site_id is not null;
if @ResourceType = 'Unit'
	begin
		select @check = 1 from @GroupNamesFilterResource1 where units_id = @resourceId;

		if(@check = 0)		
			begin
				select @check1 = 1 from prod_units_base where PU_Id = @resourceId and PL_id in (select line_id from @GroupNamesFilterResource1)
				
				if (@check1 > 0)
					begin
						select response = 'true'
					end
				else 
					begin
						select @check1 = 1 from prod_units_base pub  
						inner join Prod_Lines_Base plb on plb.PL_Id = pub.PL_Id
						where PU_Id = @resourceId and plb.Dept_id in (select department_id from @GroupNamesFilterResource1)
						if (@check1 >0)
							begin
								select response = 'true'
							end
						else if(@siteCheck>0 and EXISTS(select PU_Id from prod_units_base where PU_Id = @resourceId))
							begin
								select response = 'true'
							end
						else
							begin
								select response = 'false'
							end
						
					end
			end
		else 
			begin
				select response = 'true'
			end
	end

if @ResourceType = 'Line'
	begin
		select @check = 1 from @GroupNamesFilterResource1 where line_id = @resourceId;
		if(@check = 0)		
			begin
				select @check1 = 1 from Prod_Lines_Base where PL_Id = @resourceId and dept_id in (select department_id from @GroupNamesFilterResource1)
				if (@check1 > 0)
					begin
						select response = 'true'
					end
				else if(@siteCheck>0 and EXISTS(select PL_Id from Prod_Lines_Base where PL_Id = @resourceId))
					begin
						select response = 'true'
					end
				else 
					begin
						select response = 'false'
					end
			end
		else 
			begin
				select response = 'true'
			end
	end

if @ResourceType = 'Department'
	begin
		select @check = 1 from @GroupNamesFilterResource1 where department_id = @resourceId;

		if (@check > 0)
			begin
				select response = 'true'
			end
		else if(@siteCheck>0 and EXISTS(select db.Dept_Id from Departments_Base db where Dept_Id= @resourceId))
			begin
				select response = 'true'
			end
		else
			begin
				select response = 'false'
			end


	end
if @ResourceType = 'Site'
	begin
		select @check = 1 from @GroupNamesFilterResource1 where site_id = @resourceId;

		if (@check > 0)
			begin
				select response = 'true'
			end
		else
			begin
				select response = 'false'
			end
    end
end