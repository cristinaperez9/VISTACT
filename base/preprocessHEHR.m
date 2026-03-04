function [im]=preprocessHEHR(im,PadAmount)
% -------------------------------------------------------------------------
% Pad histology image for registration
% -------------------------------------------------------------------------
% Cristina Almagro Pérez, 2023, ETH Zürich
% -------------------------------------------------------------------------
    a=im(:,:,1);b=im(:,:,2);c=im(:,:,3);
    PadValuea=mode(a(:));PadValueb=mode(b(:));PadValuec=mode(c(:));
    ima=padarray(im(:,:,1),[PadAmount,PadAmount],PadValuea,'pre');
    imb=padarray(im(:,:,2),[PadAmount,PadAmount],PadValueb,'pre');
    imc=padarray(im(:,:,3),[PadAmount,PadAmount],PadValuec,'pre');
    ima=padarray(ima,[PadAmount,PadAmount],PadValuea,'post');
    imb=padarray(imb,[PadAmount,PadAmount],PadValueb,'post');
    imc=padarray(imc,[PadAmount,PadAmount],PadValuec,'post');        
    im=cat(3,ima,imb,imc);
end