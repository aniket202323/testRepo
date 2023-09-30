CREATE TABLE [dbo].[CXS_Route] (
    [Route_Id]      SMALLINT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Route_Desc]    [dbo].[Varchar_Desc] NOT NULL,
    [Should_Buffer] TINYINT              NULL,
    CONSTRAINT [CXS_Route_PK_RouteId] PRIMARY KEY CLUSTERED ([Route_Id] ASC),
    CONSTRAINT [CXS_Route_UC_RouteDesc] UNIQUE NONCLUSTERED ([Route_Desc] ASC)
);

