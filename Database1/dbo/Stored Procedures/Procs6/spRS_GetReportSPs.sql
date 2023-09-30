CREATE PROCEDURE dbo.spRS_GetReportSPs 
AS
select distinct o.Name
from sysobjects o
join Syscomments c on c.id = o.id
where o.type = 'p'and c.encrypted = 0 and o.Name like 'splocal%' 
order by name asc
/*
select Name
from sysobjects 
where type = 'p'
and 
(name like ('spre%')
or name like('sprs%')
or name like('splocal%'))
order by name asc
*/
