Create Procedure dbo.spSV_GetSheetShortcuts
@Sheet_Id int,
@Group_Id int
AS
SELECT *
FROM Sheet_Shortcuts S
JOIN Sheet_Shortcut_Data D on D.Sheet_Shortcut_Id = S.Sheet_Shortcut_Id
WHERE D.Sheet_Id = @Sheet_Id
AND D.Group_Id = @Group_Id
ORDER BY S.Sheet_Shortcut_Desc
