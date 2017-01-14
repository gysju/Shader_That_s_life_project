using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostProcessCamera : MonoBehaviour {

	public Material firstEffect;
    public Material secondeEffect;

    public bool useFirstEffect = true;
    void OnRenderImage( RenderTexture source, RenderTexture destination)
	{
        if( useFirstEffect == true)
	    {
            Graphics.Blit (source, destination, firstEffect);
        }
        else
            Graphics.Blit(source, destination, secondeEffect);
    }
}
