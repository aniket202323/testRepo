CREATE TABLE [dbo].[Unit_Types] (
    [Unit_Type_Id]    INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Icon_Id]         INT          NULL,
    [Uses_Locations]  BIT          NOT NULL,
    [Uses_Production] BIT          NOT NULL,
    [UT_Desc]         VARCHAR (50) NOT NULL,
    CONSTRAINT [UnitTypes_PK_UnitTypeId] PRIMARY KEY CLUSTERED ([Unit_Type_Id] ASC),
    CONSTRAINT [ProdUnitsUnitType_FK_Icons] FOREIGN KEY ([Icon_Id]) REFERENCES [dbo].[Icons] ([Icon_Id])
);

