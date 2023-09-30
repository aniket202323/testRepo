CREATE TABLE [dbo].[PU_Defects] (
    [PU_Defect_Id]     INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Defect_Type_Id]   INT NOT NULL,
    [Dimension_Spec_A] INT NULL,
    [Dimension_Spec_X] INT NULL,
    [Dimension_Spec_Y] INT NULL,
    [Dimension_Spec_Z] INT NULL,
    [PU_Id]            INT NOT NULL,
    CONSTRAINT [PUDefects_PK_PUDefectId] PRIMARY KEY CLUSTERED ([PU_Defect_Id] ASC),
    CONSTRAINT [PU_Defects_FK_DefectTypeId] FOREIGN KEY ([Defect_Type_Id]) REFERENCES [dbo].[Defect_Types] ([Defect_Type_Id])
);

