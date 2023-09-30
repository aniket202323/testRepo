CREATE TABLE [route].[RoutePropertyGroupAssociation] (
    [id]            BIGINT        IDENTITY (1, 1) NOT NULL,
    [associateType] VARCHAR (255) NOT NULL,
    [groupId]       VARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

