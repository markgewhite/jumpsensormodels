function harmscr = pca_fd_score( fdobj, meanfd, harmfd, nharm, doCentering )
    % Calculate the FPC scores for an exsting FPC basis
    % This code has been extracted from Ramsay's pca_fd function
    % and modified accordingly
    arguments
        fdobj           fd
        meanfd          fd
        harmfd          fd
        nharm           double
        doCentering     logical = true
    end

    fdbasis  = getbasis( fdobj );
    
    coef   = getcoef(fdobj);
    coefd  = size(coef);
    nrep   = coefd(2);
    ndim   = length(coefd);
    
    if ndim == 3
        nvar  = coefd(3);
    else
        nvar = 1;
    end
       
    if doCentering
        fdobj = fdobj - meanfd;
    end
    
    %  set up harmscr
    
    if nvar == 1
        harmscr = inprod(fdobj, harmfd);
    else
        harmscr       = zeros(nrep, nharm, nvar);
        coefarray     = getcoef(fdobj);
        harmcoefarray = getcoef(harmfd);
        for j=1:nvar
            coefj     = squeeze(coefarray(:,:,j));
            harmcoefj = squeeze(harmcoefarray(:,:,j));
            fdobjj    = fd(coefj, fdbasis);
            harmfdj   = fd(harmcoefj, fdbasis);
            harmscr(:,:,j) = inprod(fdobjj,harmfdj);
        end
    end

end