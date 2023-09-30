CREATE TABLE [dbo].[Bill_Of_Material_Starts] (
    [Start_Id]           INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BOM_Formulation_Id] BIGINT   NOT NULL,
    [End_Time]           DATETIME NULL,
    [PU_Id]              INT      NOT NULL,
    [Start_Time]         DATETIME NOT NULL,
    [User_Id]            INT      NULL,
    CONSTRAINT [BOMStarts_PK_StartId] PRIMARY KEY NONCLUSTERED ([Start_Id] ASC),
    CONSTRAINT [BOMStarts_CC_STimeETime] CHECK ([Start_Time]<[End_Time] OR [End_Time] IS NULL),
    CONSTRAINT [BOMStarts_FK_BOMFormulationId] FOREIGN KEY ([BOM_Formulation_Id]) REFERENCES [dbo].[Bill_Of_Material_Formulation] ([BOM_Formulation_Id]),
    CONSTRAINT [BOMStarts_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [BOMStarts_FK_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [BOMStarts_By_PUStartTime] UNIQUE CLUSTERED ([PU_Id] ASC, [Start_Time] ASC)
);

