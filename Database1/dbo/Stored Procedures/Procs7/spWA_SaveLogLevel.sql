CREATE procedure [dbo].[spWA_SaveLogLevel]
@Level int
AS
-- Idea: Add the site parameter if it doesn't exist
UPDATE Site_Parameters
SET Value = CONVERT(varchar(1), @Level)
WHERE Parm_Id = 312
