CREATE TABLE [dbo].[PrdExec_Input_Source_Data] (
    [PEIS_Id]      INT NOT NULL,
    [Valid_Status] INT NOT NULL,
    CONSTRAINT [PrdExecInputSrcData_PK_IdStat] PRIMARY KEY NONCLUSTERED ([PEIS_Id] ASC, [Valid_Status] ASC),
    CONSTRAINT [PrdExecInputSrcData_FK_PEISId] FOREIGN KEY ([PEIS_Id]) REFERENCES [dbo].[PrdExec_Input_Sources] ([PEIS_Id]),
    CONSTRAINT [PrdExecInputSrcData_FK_ValidStatus] FOREIGN KEY ([Valid_Status]) REFERENCES [dbo].[Production_Status] ([ProdStatus_Id])
);

