CREATE Procedure dbo.spDBR_Logout
AS
SET ANSI_WARNINGS off
select dbo.fnDBTranslate(N'0', 38061, 'Logout') as prompt
