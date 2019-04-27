function [hyperVolume, normallyVolume, poorVolume, nonVolume,...
    hyperMass, normallyMass, poorMass, nonMass,...
    pHyperVolume, pNormallyVolume, pPoorVolume, pNonVolume,...
    pHyperMass, pNormallyMass, pPoorMass, pNonMass] = aerationIndices(...
    huValues, volumePerDensity, massPerDensity)

    idxHyper = huValues >= -1000 & huValues < -900;
    idxNormally = huValues >= -900 & huValues < -500;
    idxPoor = huValues >= -500 & huValues < -100;
    idxNon = huValues >= -100 & huValues < 100;
    
    hyperVolume = sum(volumePerDensity(idxHyper));
    normallyVolume = sum(volumePerDensity(idxNormally));
    poorVolume = sum(volumePerDensity(idxPoor));
    nonVolume = sum(volumePerDensity(idxNon));
    
    hyperMass = sum(massPerDensity(idxHyper));
    normallyMass = sum(massPerDensity(idxNormally));
    poorMass = sum(massPerDensity(idxPoor));
    nonMass = sum(massPerDensity(idxNon));
    
    totalVolume = hyperVolume + normallyVolume + poorVolume + nonVolume;
    totalMass = hyperMass + normallyMass + poorMass + nonMass;
    
    pHyperVolume = hyperVolume / totalVolume * 100;
    pNormallyVolume = normallyVolume / totalVolume * 100;
    pPoorVolume = poorVolume / totalVolume * 100;
    pNonVolume = nonVolume / totalVolume * 100;
  
    pHyperMass = hyperMass / totalMass * 100;
    pNormallyMass = normallyMass / totalMass * 100;
    pPoorMass = poorMass / totalMass * 100;
    pNonMass = nonMass / totalMass * 100;
end