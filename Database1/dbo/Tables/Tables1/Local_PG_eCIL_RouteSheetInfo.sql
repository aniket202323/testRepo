CREATE TABLE [dbo].[Local_PG_eCIL_RouteSheetInfo] (
    [RouteSheetInfo_Id] INT IDENTITY (1, 1) NOT NULL,
    [Route_Id]          INT NOT NULL,
    [IsCreateActivity]  BIT NULL,
    [Trigger_Option_Id] INT NULL,
    [Sheet_Id]          INT NULL
);

