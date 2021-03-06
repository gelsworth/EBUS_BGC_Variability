function flux = fco2_linearize(bar,prm)

    %-- return meta data only
    if isempty(bar) && isempty(prm)
        flux_flds_1 = {'fice','k','a','Xco2','Patm','pco2'};
        
        flux_flds_2 = {'ficek_cov','ficea_cov','ficeXco2_cov','ficePatm_cov','ficepco2_cov',...
                       'ka_cov','kXco2_cov','kPatm_cov','kpco2_cov',...
                       'aXco2_cov','aPatm_cov','apco2_cov','Xco2Patm_cov'};

        flux_flds_3 = {'ficeka_cov','ficekXco2_cov','ficekPatm_cov','ficekpco2_cov','ficeaXco2_cov',...
                       'ficeaPatm_cov','ficeapco2_cov','ficeXco2Patm_cov',...
                       'kaXco2_cov','kaPatm_cov','kXco2Patm_cov','kapco2_cov',...
                       'aXco2Patm_cov'};
        
        flux_flds_4 = {'ficekaXco2_cov','ficekaPatm_cov','ficeaXco2Patm_cov','ficekXco2Patm_cov','ficekapco2_cov',...
                       'kaXco2Patm_cov'};
        
        flux_flds_5 = {'ficekaXco2Patm_cov'};       
        
        %--- meta data
        flux.Dpco2      = '(\DeltapCO_2)^\prime';
        flux.ficeka_bar = 'flux scale on pCO_2^{ocn}';        
        flux.total      = '(F_{CO_2})^\prime';
        flux.error      = 'Linearization error';
        
        for f = [flux_flds_1,flux_flds_2,flux_flds_3,flux_flds_4,flux_flds_5]
            ff = f{1};
            ff = strrep(ff,'_cov','');
            ff = strrep(ff,'Patm','(P_qtm)^{\prime}');
            ff = strrep(ff,'a','(\alpha)^\prime');
            ff = strrep(ff,'qtm','(atm)');
            ff = strrep(ff,'Xco2','(X_{co2})^{\prime}');            
            ff = strrep(ff,'fice','(f_{ice})^{\prime}');            
            ff = strrep(ff,'k','(k)^{\prime}');            
            ff = strrep(ff,'pco2','(pCO_2^{ocn})^{\prime}');            
            flux.(f{1}) = ff;
        end
        return
    end
        
    
    %-- assign input fields
    flds = fieldnames(bar);

    possible.fice    = {'fice','ECOSYS_IFRAC','IFRAC','ifrac'};
    possible.k       = {'k','ECOSYS_XKW','xkw','XKW'};
    possible.a       = {'alpha','co2_sol','a'};
    
    possible.Patm = {'ECOSYS_ATM_PRESS','Patm','P','slp'};
    possible.Xco2 = {'Xco2','ATM_CO2'};
    possible.pco2 = {'pco2','pco2ocn','pCO2SURF'};    

    pflds = fieldnames(possible);
    
    fice  = '';
    k    = '';
    a    = '';
    pco2 = '';
    Patm = '';
    Xco2 = '';
    
    for i = 1:length(flds)
        for j = 1:numel(pflds)
            nx = strcmp(possible.(pflds{j}),flds{i});
            if any(nx)
                eval([pflds{j} ' = possible.(pflds{j}){nx};'])
            end
        end
    end
    if any(strcmp({fice,k,a,pco2,Patm,Xco2},''))
        error('did not recognize incoming fields')
    end
        
    %--- first order terms
    flux.fice = (-1.0) .* prm.(fice) .* bar.(k) .* bar.(a) .* ( bar.(Xco2) .* bar.(Patm) - bar.(pco2) );
    flux.k    = ( 1 - bar.(fice) ) .* prm.(k) .* bar.(a) .* ( bar.(Xco2) .* bar.(Patm)  - bar.(pco2) );
    flux.a    = ( 1 - bar.(fice) ) .* bar.(k) .* prm.(a) .* ( bar.(Xco2) .* bar.(Patm)  - bar.(pco2) );
    flux.Xco2 = ( 1 - bar.(fice) ) .* bar.(k) .* bar.(a) .* prm.(Xco2) .* bar.(Patm);
    flux.Patm = ( 1 - bar.(fice) ) .* bar.(k) .* bar.(a) .* bar.(Xco2) .* prm.(Patm);    
    flux.pco2 = (-1.0) .* ( 1 - bar.(fice) ) .* bar.(k) .* bar.(a) .* prm.(pco2);
    
    %--- second order terms
    flux.ficek_cov    = (-1.0) .* prm.(fice) .* prm.(k) .* bar.(a) .* ( bar.(Xco2) .* bar.(Patm)  - bar.(pco2) );
    flux.ficea_cov    = (-1.0) .* prm.(fice) .* bar.(k) .* prm.(a) .* ( bar.(Xco2) .* bar.(Patm)  - bar.(pco2) );
    flux.ficeXco2_cov = (-1.0) .* prm.(fice) .* bar.(k) .* bar.(a) .* prm.(Xco2) .* bar.(Patm);
    flux.ficePatm_cov = (-1.0) .* prm.(fice) .* bar.(k) .* bar.(a) .* bar.(Xco2) .* prm.(Patm);    
    flux.ficepco2_cov = ( 1.0) .* prm.(fice) .* bar.(k) .* bar.(a) .* prm.(pco2);
    
    flux.ka_cov     = ( 1 - bar.(fice) ) .* prm.(k) .* prm.(a) .* ( bar.(Xco2) .* bar.(Patm)  - bar.(pco2) );
    flux.kXco2_cov  = prm.(k) .* bar.(a) .* prm.(Xco2) .* bar.(Patm) - bar.(fice) .* prm.(k) .* bar.(a) .* prm.(Xco2) .* bar.(Patm);
    flux.kPatm_cov  = ( 1 - bar.(fice) ) .* prm.(k) .* bar.(a) .* bar.(Xco2) .* prm.(Patm);    
    flux.kpco2_cov  = (-1.0) .* ( 1 - bar.(fice) ) .* prm.(k) .* bar.(a) .* prm.(pco2);
    
    flux.aXco2_cov  = ( 1 - bar.(fice) ) .* bar.(k) .* prm.(a) .* prm.(Xco2) .* bar.(Patm);
    flux.aPatm_cov  = ( 1 - bar.(fice) ) .* bar.(k) .* prm.(a) .* bar.(Xco2) .* prm.(Patm);    
    flux.apco2_cov  = (-1.0) .* ( 1 - bar.(fice) ) .* bar.(k) .* prm.(a) .* prm.(pco2);
    
    flux.Xco2Patm_cov  = bar.(a) .* bar.(k) .* prm.(Patm)  .* prm.(Xco2) - bar.(a) .* bar.(fice) .* bar.(k) .* prm.(Patm)  .* prm.(Xco2);
   
    %--- third order terms
    flux.ficeka_cov         = (-1.0) .* prm.(fice) .* prm.(k) .* prm.(a) .* ( bar.(Xco2) .* bar.(Patm) - bar.(pco2) );
    flux.ficekXco2_cov      = (-1.0) .* bar.(a) .* bar.(Patm) .* prm.(fice) .* prm.(k) .* prm.(Xco2) ; 
    flux.ficekPatm_cov      = (-1.0) .* prm.(fice) .* prm.(k) .* bar.(a) .* bar.(Xco2) .* prm.(Patm);
    flux.ficekpco2_cov      = prm.(fice) .* prm.(k) .* bar.(a) .* prm.(pco2);
    
    flux.ficeaXco2_cov      = (-1.0) .* prm.(fice) .* bar.(k) .* prm.(a) .* prm.(Xco2) .* bar.(Patm);
    flux.ficeaPatm_cov      = (-1.0) .* prm.(fice) .* bar.(k) .* prm.(a) .* bar.(Xco2) .* prm.(Patm);
    flux.ficeapco2_cov      = prm.(fice) .* bar.(k) .* prm.(a) .* prm.(pco2);
    
    flux.ficeXco2Patm_cov   = (-1.0) .* prm.(fice) .* bar.(k) .* bar.(a) .* prm.(Xco2) .* prm.(Patm);
   
    flux.kaXco2_cov         = (1 - bar.(fice)) .* prm.(k) .* prm.(a) .* prm.(Xco2) .* bar.(Patm);  
    flux.kaPatm_cov         = (1 - bar.(fice)) .* prm.(k) .* prm.(a) .* bar.(Xco2) .* prm.(Patm);      
    flux.kXco2Patm_cov      = (1 - bar.(fice)) .* prm.(k) .* bar.(a) .* prm.(Xco2) .* prm.(Patm);  
    flux.kapco2_cov         = (-1.0) .* (1 - bar.(fice)) .* prm.(k) .* prm.(a) .* prm.(pco2);
        
    flux.aXco2Patm_cov      = (1 - bar.(fice)) .* bar.(k) .* prm.(a) .* prm.(Xco2) .* prm.(Patm);  

    %--- fourth order terms
    flux.ficekaXco2_cov     = (-1.0) .* bar.(Patm) .* prm.(a) .* prm.(fice) .* prm.(k) .* prm.(Xco2);        
    flux.ficekaPatm_cov     = (-1.0) .* prm.(fice) .* prm.(k) .* prm.(a) .* bar.(Xco2) .* prm.(Patm);        
    flux.ficeaXco2Patm_cov  = (-1.0) .* prm.(fice) .* bar.(k) .* prm.(a) .* prm.(Xco2) .* prm.(Patm);        
    flux.ficekXco2Patm_cov  = (-1.0) .* prm.(fice) .* prm.(k) .* bar.(a) .* prm.(Xco2) .* prm.(Patm);        
       
    flux.ficekapco2_cov     = prm.(fice) .* prm.(k) .* prm.(a) .* prm.(pco2);

    
    flux.kaXco2Patm_cov     = (1 - bar.(fice)) .* prm.(k) .* prm.(a) .* prm.(Xco2) .* prm.(Patm);  
    
    %--- fifth order terms
    flux.ficekaXco2Patm_cov = (-1.0) .* prm.(fice) .* prm.(k) .* prm.(a) .* prm.(Xco2) .* prm.(Patm);        
    
    %--- sum over all components
    flds = fieldnames(flux);
    flux.total = 0;
    for i = 1:numel(flds)
        f = flds{i};
        flux.total = flux.total + flux.(f);    
    end  
    
    %--- some amendments
    flux.ficeka_bar = (-1.0) .* ( 1 - bar.(fice) ) .* bar.(k) .* bar.(a);  % the derivative wrt pco2
    flux.Dpco2     = (1 - bar.(fice)) .* bar.(k) .* bar.(a) .* ( prm.(Xco2) - prm.(pco2));    
    
    if isfield(prm,'FG_CO2')
        flux.error = flux.total - prm.FG_CO2;
    end

    
    
    
    return
    flux.verify = ...
        + flux.fice ...
        + flux.a ...
        + flux.k ...
        + flux.pco2 ...
         + flux.ficea_cov ...
         + flux.ka_cov ...
         + flux.ficek_cov ...
         + flux.ficeka_cov ...
         + flux.Patm ...
         + flux.aPatm_cov ...
         + flux.ficePatm_cov ...
         + flux.ficeaPatm_cov ...
         + flux.kPatm_cov ...
         + flux.kaPatm_cov ...        
         + flux.ficekPatm_cov ...
         + flux.ficekaPatm_cov ...
         + flux.apco2_cov ...
         + flux.ficepco2_cov ...
         + flux.ficeapco2_cov ...
         + flux.kpco2_cov ...
         + flux.kapco2_cov ...        
         + flux.ficekpco2_cov ...
         + flux.ficekapco2_cov ...
         + flux.Xco2 ...
         + flux.aXco2_cov ...
         + flux.ficeXco2_cov ...
         + flux.ficeaXco2_cov ...
         + flux.kXco2_cov ...
         + flux.kaXco2_cov ...
         + flux.ficekXco2_cov ...
         + flux.ficekaXco2_cov ...
         + flux.Xco2Patm_cov ...
         + flux.aXco2Patm_cov ...
         + flux.ficeXco2Patm_cov ...
         + flux.ficeaXco2Patm_cov ...
         + flux.kXco2Patm_cov ...
         + flux.kaXco2Patm_cov ...
         + flux.ficekXco2Patm_cov ...
         + flux.ficekaXco2Patm_cov;     
     
          
    flux.verify_true = ...
        - bar.(k) .* bar.(pco2) .* prm.(a)  ...
        + bar.(fice) .* bar.(k) .* bar.(pco2) .* prm.(a) ...
        + bar.(k) .* bar.(Patm) .* bar.(Xco2) .* prm.(a)  ...
        - bar.(fice) .* bar.(k) .* bar.(Patm) .* bar.(Xco2) .* prm.(a)  ...
        + bar.(a) .* bar.(k) .* bar.(pco2) .* prm.(fice)  ...
        - bar.(a) .* bar.(k) .* bar.(Patm) .* bar.(Xco2) .* prm.(fice)  ...
        + bar.(k) .* bar.(pco2) .* prm.(a) .* prm.(fice)  ...
        - bar.(k) .* bar.(Patm) .* bar.(Xco2) .* prm.(a) .* prm.(fice) ...
        - bar.(a) .* bar.(pco2) .* prm.(k)  ...
        + bar.(a) .* bar.(fice) .* bar.(pco2) .* prm.(k) ...
        + bar.(a) .* bar.(Patm) .* bar.(Xco2) .* prm.(k)  ...
        - bar.(a) .* bar.(fice) .* bar.(Patm) .* bar.(Xco2) .* prm.(k) ...
        - bar.(pco2) .* prm.(a) .* prm.(k)  ...
        + bar.(fice) .* bar.(pco2) .* prm.(a) .* prm.(k) ...
        + bar.(Patm) .* bar.(Xco2) .* prm.(a) .* prm.(k)  ...
        - bar.(fice) .* bar.(Patm) .* bar.(Xco2) .* prm.(a) .* prm.(k)  ...
        + bar.(a) .* bar.(pco2) .* prm.(fice) .* prm.(k)  ...
        - bar.(a) .* bar.(Patm) .* bar.(Xco2) .* prm.(fice) .* prm.(k)  ...
        + bar.(pco2) .* prm.(a) .* prm.(fice) .* prm.(k)  ...
        - bar.(Patm) .* bar.(Xco2) .* prm.(a) .* prm.(fice) .* prm.(k)  ...
        + bar.(a) .* bar.(k) .* bar.(Xco2) .* prm.(Patm)  ...
        - bar.(a) .* bar.(fice) .* bar.(k) .* bar.(Xco2) .* prm.(Patm)  ...
        + bar.(k) .* bar.(Xco2) .* prm.(a) .* prm.(Patm)  ...
        - bar.(fice) .* bar.(k) .* bar.(Xco2) .* prm.(a) .* prm.(Patm)  ...
        - bar.(a) .* bar.(k) .* bar.(Xco2) .* prm.(fice) .* prm.(Patm)  ...
        - bar.(k) .* bar.(Xco2) .* prm.(a) .* prm.(fice) .* prm.(Patm)  ...
        + bar.(a) .* bar.(Xco2) .* prm.(k) .* prm.(Patm)  ...
        - bar.(a) .* bar.(fice) .* bar.(Xco2) .* prm.(k) .* prm.(Patm)  ...
        + bar.(Xco2) .* prm.(a) .* prm.(k) .* prm.(Patm)  ...
        - bar.(fice) .* bar.(Xco2) .* prm.(a) .* prm.(k) .* prm.(Patm)  ...
        - bar.(a) .* bar.(Xco2) .* prm.(fice) .* prm.(k) .* prm.(Patm)  ...
        - bar.(Xco2) .* prm.(a) .* prm.(fice) .* prm.(k) .* prm.(Patm) ...
        - bar.(a) .* bar.(k) .* prm.(pco2)  ...
        + bar.(a) .* bar.(fice) .* bar.(k) .* prm.(pco2) ...
        - bar.(k) .* prm.(a) .* prm.(pco2)  ...
        + bar.(fice) .* bar.(k) .* prm.(a) .* prm.(pco2) ...
        + bar.(a) .* bar.(k) .* prm.(fice) .* prm.(pco2)  ...
        + bar.(k) .* prm.(a) .* prm.(fice) .* prm.(pco2) ...
        - bar.(a) .* prm.(k) .* prm.(pco2)  ...
        + bar.(a) .* bar.(fice) .* prm.(k) .* prm.(pco2) ...
        - prm.(a) .* prm.(k) .* prm.(pco2)  ...
        + bar.(fice) .* prm.(a) .* prm.(k) .* prm.(pco2) ...
        + bar.(a) .* prm.(fice) .* prm.(k) .* prm.(pco2)  ...
        + prm.(a) .* prm.(fice) .* prm.(k) .* prm.(pco2) ...
        + bar.(a) .* bar.(k) .* bar.(Patm) .* prm.(Xco2)  ...
        - bar.(a) .* bar.(fice) .* bar.(k) .* bar.(Patm) .* prm.(Xco2)  ...
        + bar.(k) .* bar.(Patm) .* prm.(a) .* prm.(Xco2)  ...
        - bar.(fice) .* bar.(k) .* bar.(Patm) .* prm.(a) .* prm.(Xco2)  ...
        - bar.(a) .* bar.(k) .* bar.(Patm) .* prm.(fice) .* prm.(Xco2)  ...
        - bar.(k) .* bar.(Patm) .* prm.(a) .* prm.(fice) .* prm.(Xco2)  ...
        + bar.(a) .* bar.(Patm) .* prm.(k) .* prm.(Xco2)  ...
        - bar.(a) .* bar.(fice) .* bar.(Patm) .* prm.(k) .* prm.(Xco2)  ...
        + bar.(Patm) .* prm.(a) .* prm.(k) .* prm.(Xco2)  ...
        - bar.(fice) .* bar.(Patm) .* prm.(a) .* prm.(k) .* prm.(Xco2)  ...
        - bar.(a) .* bar.(Patm) .* prm.(fice) .* prm.(k) .* prm.(Xco2)  ...
        - bar.(Patm) .* prm.(a) .* prm.(fice) .* prm.(k) .* prm.(Xco2)  ...
        + bar.(a) .* bar.(k) .* prm.(Patm) .* prm.(Xco2)  ...
        - bar.(a) .* bar.(fice) .* bar.(k) .* prm.(Patm) .* prm.(Xco2)  ...
        + bar.(k) .* prm.(a) .* prm.(Patm) .* prm.(Xco2)  ...
        - bar.(fice) .* bar.(k) .* prm.(a) .* prm.(Patm) .* prm.(Xco2)  ...
        - bar.(a) .* bar.(k) .* prm.(fice) .* prm.(Patm) .* prm.(Xco2)  ...
        - bar.(k) .* prm.(a) .* prm.(fice) .* prm.(Patm) .* prm.(Xco2)  ...
        + bar.(a) .* prm.(k) .* prm.(Patm) .* prm.(Xco2)  ...
        - bar.(a) .* bar.(fice) .* prm.(k) .* prm.(Patm) .* prm.(Xco2)  ...
        + prm.(a) .* prm.(k) .* prm.(Patm) .* prm.(Xco2)  ...
        - bar.(fice) .* prm.(a) .* prm.(k) .* prm.(Patm) .* prm.(Xco2)  ...
        - bar.(a) .* prm.(fice) .* prm.(k) .* prm.(Patm) .* prm.(Xco2)  ...
        - prm.(a) .* prm.(fice) .* prm.(k) .* prm.(Patm) .* prm.(Xco2);
    
   
   


   
