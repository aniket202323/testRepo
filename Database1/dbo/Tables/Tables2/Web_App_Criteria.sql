CREATE TABLE [dbo].[Web_App_Criteria] (
    [WAC_Id]           INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ED_Field_Type_Id] INT           NOT NULL,
    [Field_Name]       VARCHAR (255) NULL,
    [Table_Name]       VARCHAR (255) NULL,
    [WAC_Desc]         VARCHAR (50)  NOT NULL,
    [WAT_Id]           INT           NOT NULL,
    CONSTRAINT [PK_Web_App_Criteria] PRIMARY KEY NONCLUSTERED ([WAC_Id] ASC),
    CONSTRAINT [WAC_EDF] FOREIGN KEY ([ED_Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id]),
    CONSTRAINT [WAC_WAT] FOREIGN KEY ([WAT_Id]) REFERENCES [dbo].[Web_App_Types] ([WAT_Id])
);

