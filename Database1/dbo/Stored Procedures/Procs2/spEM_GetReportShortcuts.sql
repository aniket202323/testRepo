Create Procedure dbo.spEM_GetReportShortcuts
   @PU_Id             int,
   @App_Id            int
  AS
  --
  -- Declare local variables.
  --
    SELECT  Report_Shortcut_Id,Report_Name,Document_Name FROM Report_Shortcuts
    WHERE   PU_Id  = @PU_Id
       AND  App_Id = @App_Id
