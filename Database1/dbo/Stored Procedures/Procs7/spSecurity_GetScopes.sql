
CREATE PROCEDURE dbo.spSecurity_GetScopes
@GroupIds nvarchar(max) ,				/* user group names				*/
@AssignmentIds nvarchar(max) 				/* user group names				*/

--@returnMessage nvarchar(100)

AS
CREATE TABLE #GroupIds(G_Id nvarchar(4000))
CREATE TABLE #AssignmentIds(A_Id int)


DECLARE @SQLStr nvarchar(max)
DECLARE @delimiter as nVarChar(10)
DECLARE @xmls as xml


if (@GroupIds is not null)
		Begin
			SET @delimiter =','
			SET @xmls = cast(('<X>'+replace(@GroupIds,@delimiter ,'</X><X>')+'</X>') as xml)
			INSERT INTO #GroupIds (G_Id)  
			SELECT N.value('.', 'nvarchar(max)') as value FROM @xmls.nodes('X') as T(N)
		End

if (@AssignmentIds is not null)
		Begin
			SET @delimiter =','
			SET @xmls = cast(('<X>'+replace(@AssignmentIds,@delimiter ,'</X><X>')+'</X>') as xml)
			INSERT INTO #AssignmentIds (A_Id)  
			SELECT N.value('.', 'int') as value FROM @xmls.nodes('X') as T(N)
		End


SELECT distinct a.id as assignmentId , agd.group_id as groupId, rb.name scope FROM security.Assignments a  
inner join [security].[Assignment_Group_Details] agd on agd.assignment_id = a.id and agd.group_id in (select G_Id from #GroupIds)
inner join [security].[Assignment_Role_Details] ard on ard.assignment_id = a.id 
inner join [security].[Role_Base] rb on rb.id =ard.role_id 
where a.id not in (select A_Id from #AssignmentIds)



