CREATE TABLE [dbo].[CXS_Route_Data] (
    [ApplicationName] VARCHAR (100) CONSTRAINT [CXSRouteData_DF_ApplicationName] DEFAULT ('') NOT NULL,
    [Domain]          VARCHAR (100) CONSTRAINT [CXSRouteData_DF_Domain] DEFAULT ('') NOT NULL,
    [KeyMask]         VARCHAR (500) CONSTRAINT [CXSRouteData_DF_KeyMask] DEFAULT ('') NOT NULL,
    [RG_Id]           SMALLINT      NOT NULL,
    [Route_Id]        SMALLINT      NOT NULL,
    CONSTRAINT [CXSRouteData_PK_RouteRGIdAppDomainMask] PRIMARY KEY CLUSTERED ([Route_Id] ASC, [RG_Id] ASC, [ApplicationName] ASC, [Domain] ASC, [KeyMask] ASC),
    CONSTRAINT [CXS_Route_Data_FK_RGId] FOREIGN KEY ([RG_Id]) REFERENCES [dbo].[CXS_Route_Group] ([RG_Id])
);

