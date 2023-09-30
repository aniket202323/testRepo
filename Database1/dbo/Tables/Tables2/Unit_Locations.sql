CREATE TABLE [dbo].[Unit_Locations] (
    [Location_Id]           INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]            INT          NULL,
    [Location_Code]         VARCHAR (50) NULL,
    [Location_Desc]         VARCHAR (50) NULL,
    [Maximum_Alarm_Enabled] BIT          NOT NULL,
    [Maximum_Dimension_A]   REAL         NULL,
    [Maximum_Dimension_X]   REAL         NULL,
    [Maximum_Dimension_Y]   REAL         NULL,
    [Maximum_Dimension_Z]   REAL         NULL,
    [Maximum_Items]         INT          NULL,
    [Minimum_Alarm_Enabled] BIT          NOT NULL,
    [Minimum_Dimension_A]   REAL         NULL,
    [Minimum_Dimension_X]   REAL         NULL,
    [Minimum_Dimension_Y]   REAL         NULL,
    [Minimum_Dimension_Z]   REAL         NULL,
    [Minimum_Items]         INT          NULL,
    [Prod_Id]               INT          NULL,
    [PU_Id]                 INT          NULL,
    CONSTRAINT [UnitLocations_PK_LocationId] PRIMARY KEY CLUSTERED ([Location_Id] ASC),
    CONSTRAINT [UnitLocations_FK_Products] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [UnitLocations_UC_PUIDCode] UNIQUE NONCLUSTERED ([PU_Id] ASC, [Location_Code] ASC)
);

