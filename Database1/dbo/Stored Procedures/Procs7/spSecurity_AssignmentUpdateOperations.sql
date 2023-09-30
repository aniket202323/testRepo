
CREATE PROCEDURE dbo.spSecurity_AssignmentUpdateOperations
@AssignmentId int  = null,						/*		Assignment id			*/
@AName nvarchar(100) = null,						/*		assignment name			*/
@ADescription nvarchar(100) = null,				/*		descpription			*/
@GroupIds nvarchar(max) =null,					/*		group names				*/
@RoleIds nvarchar(100) = null,					/*		role id's				*/
@LineIds nvarchar(100) = null,					/*		line id's				*/
@UnitIds nvarchar(100) = null,					/*		unit id's				*/
@ProductIds nvarchar(100) = null,				/*		product id's			*/
@ProductFamilyIds nvarchar(100) = null,			/*		product family id's		*/
@DepartmentIds nvarchar(100) = null,				/*		department id's			*/
@SiteIds nvarchar(100) = null,					/*		site id's			*/
@ModifiedBy  nvarchar(max) = null,				/*		modified by				*/
@ModifiedDate datetime2 = null,					/*		modified date			*/
@returnMessage nvarchar(100) = null				/*		return massage			*/

--@assignmentInfo 
AS

CREATE TABLE #AllUnits(u_id Int)
--select id,name,description from security.Assignments
CREATE TABLE #AllLines(l_id Int)
CREATE TABLE #AllProducts(p_id int)
CREATE TABLE #LineIds(L_Id Int)
CREATE TABLE #ProdIds(P_Id Int)
CREATE TABLE #UnitIds(U_Id Int)
CREATE TABLE #ProductIds(P_Id Int)
CREATE TABLE #ProductFamilyIds(PF_Id Int)
CREATE TABLE #RoleIds(R_Id Int)
CREATE TABLE #GroupIds(G_Id nvarchar(max))
CREATE TABLE #DepartmentIds(D_Id Int)
CREATE TABLE #SiteIds(S_Id Int)


DECLARE @SQLL nvarchar(max)
DECLARE @SQLStr nvarchar(max)
DECLARE @SQLStss nvarchar(max)
DECLARE @SQLStsLine nvarchar(max)
DECLARE @SQLStsUnit nvarchar(max)
DECLARE @SQLStsssLR nvarchar(max)
DECLARE @SQLStsssUR nvarchar(max)
DECLARE @SQLStsssPR nvarchar(max)
DECLARE @SQLStsProduct nvarchar(max)
DECLARE @SQLStsssPFR nvarchar(max)
DECLARE @SQLSts nvarchar(max)
DECLARE @cnt nvarchar(200);
DECLARE @chck nvarchar(200);
DECLARE @AId Int; 
declare @tem nvarchar(200);
Declare @TotalsizeInput int;
Declare @TotalsizePermissions int;
Declare @chckError int;


DECLARE @TestError Int; 

DECLARE @Message nvarchar(2048) = ERROR_MESSAGE();
        DECLARE @Severity integer = ERROR_SEVERITY();
        DECLARE @State integer = ERROR_STATE();

DECLARE @xmls as xml,@str as nvarchar(100),@delimiter as nVarChar(10)
DECLARE @xml XML

BEGIN TRANSACTION;
if (@RoleIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@RoleIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #RoleIds (R_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End

if (@GroupIds is not null)
		Begin
			SET @delimiter =','
			SET @xmls = cast(('<X>'+replace(@GroupIds,@delimiter ,'</X><X>')+'</X>') as xml)
			INSERT INTO #GroupIds (G_Id)  
			SELECT N.value('.', 'nvarchar(max)') as value FROM @xmls.nodes('X') as T(N)
		End


if (@LineIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@LineIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #LineIds (L_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End

if (@UnitIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@UnitIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #UnitIds (U_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End

if (@ProductIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@ProductIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #ProductIds (P_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End

if (@ProductFamilyIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@ProductFamilyIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #ProductFamilyIds (PF_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End

if (@DepartmentIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@DepartmentIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #DepartmentIds (D_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End

if (@SiteIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@SiteIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #SiteIds (S_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End



begin

			
			

			IF (NOT EXISTS(SELECT 1 FROM [security].[Assignments] WHERE id = @AssignmentId) and @AssignmentId is not Null)
				BEGIN
					select @chckError = 1
					SELECT Error = 'Assignment Id not found','ESS1021' as Code					 
				END

			select @chck = name from [security].[Assignments] where name = @AName and id not in (@AssignmentId)			
			if @chck is not null and @chckError is null
				begin
						select @chckError = 1
						select Error = 'Assignment name already exist','ESS1022' as Code					 
				end 

			
			
			select @TotalsizeInput = count(*) from #RoleIds
			select @TotalsizePermissions =  count(*) from security.Role_Base where id in (select * from #RoleIds)
			if @TotalsizeInput <> @TotalsizePermissions and @chckError is null
			begin
				select @chck = '1'
				select Error = 'Role ids not exist','ESS1023' as Code
			end
			
			select @TotalsizeInput = count(*) from #LineIds 
			select @TotalsizePermissions =  count(*) from dbo.Prod_Lines_Base where PL_Id in (select * from #LineIds)
			if @TotalsizeInput <> @TotalsizePermissions and @chckError is null
			begin
				select @chck = '1'
				select Error = 'Line ids not exist','ESS1024' as Code
			end

			select @TotalsizeInput = count(*) from #UnitIds
			select @TotalsizePermissions =  count(*) from dbo.Prod_Units_Base where PU_Id in (select * from #UnitIds)
			if @TotalsizeInput <> @TotalsizePermissions and @chckError is null
			begin
				select @chck = '1'
				select Error = 'Unit ids not exist','ESS1025' as Code
			end

			select @TotalsizeInput = count(*) from #ProductIds
			select @TotalsizePermissions =  count(*) from dbo.Products_Base where Prod_Id in (select * from #ProductIds)
			if @TotalsizeInput <> @TotalsizePermissions and @chckError is null
			begin
				select @chck = '1'
				select Error = 'Product ids not exist','ESS1026' as Code
			end


			select @TotalsizeInput = count(*) from #ProductFamilyIds
			select @TotalsizePermissions =  count(*) from dbo.Product_Family where Product_Family_Id in (select * from #ProductFamilyIds)
			if @TotalsizeInput <> @TotalsizePermissions and @chckError is null
			begin
				select @chck = '1'
				select Error = 'Product Family ids not exist','ESS1027' as Code
			end

			select @TotalsizeInput = count(*) from #DepartmentIds
			select @TotalsizePermissions =  count(*) from dbo.Departments_Base where Dept_Id in (select * from #DepartmentIds)
			if @TotalsizeInput <> @TotalsizePermissions
			begin
				select @chck = '1'
				select Error = 'Department id not exist','ESS1028' as Code
			end

end


Begin	
if @AssignmentId is not null and @chck is null

		if @chck is null
		begin
			update [security].[Assignments] set name=@AName,
											description = @ADescription,
											modified_by = @ModifiedBy,
											modified_date = @ModifiedDate
											where id =@AssignmentId;
											
											
											
		end
	Select @AId = CAST(Scope_Identity() AS int)
end

Begin
if (@chck is null) and (@chckError is null)
	BEGIN
		delete from [security].[Assignment_Role_Details] where assignment_id in (@AssignmentId);
		INSERT INTO [security].[Assignment_Role_Details] (assignment_id,role_id) select @AssignmentId,  R_Id from #RoleIds		
	END
end

Begin
if (@chck is null) and (@chckError is null)
	BEGIN
		delete from [security].[Assignment_Group_Details] where assignment_id in (@AssignmentId);
		INSERT INTO [security].[Assignment_Group_Details] (assignment_id,group_id) select @AssignmentId,  G_Id from #GroupIds
	END
end


Begin
if (@chck is null) and (@chckError is null)		
	BEGIN
		delete from [security].[Line_Resource_Details] where assignment_id in (@AssignmentId);
		INSERT INTO [security].[Line_Resource_Details] (assignment_id,line_id) select @AssignmentId,  L_Id from #LineIds
	END
end

begin
if (@chck is null) and (@chckError is null)
	Begin
		delete from [security].[Units_Resource_Details] where assignment_id in (@AssignmentId);	
		INSERT INTO [security].[Units_Resource_Details] (assignment_id,units_id) select @AssignmentId,  U_id from #UnitIds
	end
end

begin
if (@chck is null) and (@chckError is null)
	begin
		delete from [security].[Product_Resource_Details] where assignment_id in (@AssignmentId);	
		INSERT INTO [security].[Product_Resource_Details] (assignment_id,product_id) select @AssignmentId ,  P_Id from #ProductIds
	end
end

begin
if (@chck is null) and (@chckError is null)
	Begin
		delete from [security].[Product_Family_Resource_Details] where assignment_id in (@AssignmentId);	
		INSERT INTO [security].[Product_Family_Resource_Details] (assignment_id,product_family_id) select @AssignmentId,  PF_Id from #ProductFamilyIds
	end	
end

begin
if (@chck is null) and (@chckError is null)
	Begin
		delete from [security].[Department_Resource_Details] where assignment_id in (@AssignmentId);	
		INSERT INTO [security].[Department_Resource_Details] (assignment_id,department_id) select @AssignmentId,  D_Id from #DepartmentIds
	end	
end

begin
if (@chck is null) and (@chckError is null)
	Begin
		delete from [security].[Site_Resource_Details] where assignment_id in (@AssignmentId);	
		INSERT INTO [security].[Site_Resource_Details] (assignment_id,site_id) select @AssignmentId, S_Id from #SiteIds
	end	
end


commit


if @chckError is null and @chck is null
	begin
		SELECT DISTINCT a.id as assignment_id ,a.name,a.description,a.created_by,a.created_date,a.modified_by,a.modified_date,agd.group_id ,ard.role_id,lrd.line_id ,
		urd.units_id ,pfrd.product_family_id ,prd.product_id ,drd.department_id, srd.site_id FROM security.Assignments a 
		left join [security].[Assignment_Group_Details] agd on agd.assignment_id = a.id 
		left join [security].[Assignment_Role_Details] ard on ard.assignment_id = a.id 
		left join [security].[Line_Resource_Details] lrd on lrd.assignment_id = a.id 
		left join [security].[Units_Resource_Details] urd on urd.assignment_id = a.id 
		left join [security].[Product_Family_Resource_Details] pfrd on pfrd.assignment_id = a.id 
		left join [security].[Product_Resource_Details] prd on prd.assignment_id = a.id 
		left join [security].[Department_Resource_Details] drd on drd.assignment_id = a.id 
		left join [security].[Site_Resource_Details] srd on srd.assignment_id = a.id 
		where a.id=@AssignmentId
	end


