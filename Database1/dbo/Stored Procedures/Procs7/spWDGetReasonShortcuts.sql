Create Procedure dbo.spWDGetReasonShortcuts
@pApp_Id int,
@pPU_Id int
AS
Select @pApp_Id = @pApp_Id + 1
SELECT *
FROM Reason_Shortcuts
WHERE App_Id = @pApp_Id
AND PU_Id = @pPU_Id
ORDER BY Shortcut_Name
RETURN(100)
