INSERT INTO edi.code_value 
VALUES      ( code_value_seq.NEXTVAL, 
             (SELECT code_set 
              FROM   edi.code_set 
              WHERE  code_set_name = 'FUNCTIONAL_TRANSACTION_STATUS'), 
             'EPAYMENT_RECON_JENKINS_SAMPLE', 
             'testhavingerror_022', 
             1, 
             SYSDATE, 
             SYSDATE, 
             SYSDATE);
